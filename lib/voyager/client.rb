require 'zoom'

module Voyager
  class Client
    include Voyager::ClientBehavior::OracleQueryBehavior
    include Voyager::ClientBehavior::HoldingsRetrieval
    include Voyager::ClientBehavior::BibRecordRetrieval

    REQUIRED_Z3950_CONFIG_OPTS = [:host, :port, :database_name].freeze
    REQUIRED_ORACLE_CONFIG_OPTS = [:host, :port, :database_name, :user, :password].freeze
    ORACLE_RETRIEVAL_BATCH_SIZE = 100

    def initialize(config)
      @z3950_config = config[:z3950]
      # The ZOOM library has a bug where if the supplied host argument is nil,
      # the native, backing yaz library throws an error that can't be caught
      # by ruby, so we need to ensure that config[:host'] is never nil. And as
      # long as we're checking for host, we'll check for other required config
      # options too.
      REQUIRED_Z3950_CONFIG_OPTS.each do |required_config_opt|
        raise ArgumentError, "Missing z3950 config[:#{required_config_opt}] for #{self.class}" unless @z3950_config[required_config_opt].present?
      end

      @oracle_config = config[:oracle]
      # Make sure oracle config options are present so there aren't any surprises later when queries are run
      REQUIRED_Z3950_CONFIG_OPTS.each do |required_config_opt|
        raise ArgumentError, "Missing oracle config[:#{required_config_opt}] for #{self.class}" unless @oracle_config[required_config_opt].present?
      end
    end

    def oracle_connection
      @oracle_connection ||= OCI8.new(
        @oracle_config[:user],
        @oracle_config[:password],
        "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=#{@oracle_config[:host]})(PORT=#{@oracle_config[:port]}))(CONNECT_DATA=(SID=#{@oracle_config[:database_name]})))"
      ).tap do |connection|
        # When a select statement is executed, the OCI library allocates
        # a prefetch buffer to reduce the number of network round trips by
        # retrieving specified number of rows in one round trip.
        connection.prefetch_rows = 1000
      end
    end

    def break_oracle_connection!
      @oracle_connection.break
      # Attempt a clean disconnect from Oracle and then set the connection
      # variable to nil so that the oracle_connection method
      # re-establishes the connection when it is called again.
      @oracle_connection = nil
    end

    # Finds a single record by bib id
    # @return [MARC::Record] The MARC record associated with the given id.
    def search_by_965_value(string_965_value)
      search(1, 9000, string_965_value) do |marc_record, i, num_results, unexpected_error|
        yield marc_record, i, num_results, unexpected_error
      end
    end

    def clear_search_cache(query_type, query_field, query_value)
      path = search_cache_path(query_type, query_field, query_value)
      FileUtils.rm_rf(path)
      if File.exist?(path)
        Rails.logger.error "Tried to delete search cache at #{path}, but it still exists! Maybe an NFS lock issue?"
      end
    end

    def search_cache_exists?(query_type, query_field, query_value)
      File.exist?(search_cache_path(query_type, query_field, query_value))
    end

    def search_cache_path(query_type, query_field, query_value)
      Rails.root.join('tmp', 'z3950_cache', "#{query_type}-#{query_field}-#{query_value}")
    end

    # @param record [ZOOM::Record]
    def bib_id_for_zoom_record(record)
      MARC::Record.new_from_marc(record.raw)['001'].value
    end

    def search(query_type, query_field, query_value)
      # Clear cached results if we don't want to use cached results
      clear_search_cache(query_type, query_field, query_value) if !@z3950_config[:use_cached_results]
      cache_path = search_cache_path(query_type, query_field, query_value)

      if !search_cache_exists?(query_type, query_field, query_value)
        FileUtils.mkdir_p(cache_path)
        Rails.logger.debug("Downloading MARC records to #{cache_path}. This may take a while...")
        duration = Benchmark.realtime do
          ZOOM::Connection.open(@z3950_config[:host], @z3950_config[:port]) do |conn|
            conn.database_name = @z3950_config[:database_name]
            conn.preferred_record_syntax = 'USMARC'
            result_set = conn.search("@attr #{query_type}=#{query_field} #{query_value}")
            last_result_index = result_set.length - 1
            batch = []
            for i in 0..(last_result_index) do
              # We get bib_ids from Z39.50 because Z39.50 supports 965-field lookups, but we
              # retrieve records directly from Voyager's Oracle DB so that we get UTF-8 records.
              # This is necessary because Voyager's Z39.50 is not set up to return UTF-8.
              #
              # Retrieving records in batches is faster than retrieving them one by one, since
              # indivudal lookups would require one SQL query per record.
              batch << bib_id_for_zoom_record(result_set[i])
              if i === last_result_index || batch.length == ORACLE_RETRIEVAL_BATCH_SIZE
                bib_records_for_batch = retrieve_multiple_bib_marc_records(batch)
                bib_records_for_batch.each do |bib_id, marc_record|
                  path_to_file = File.join(cache_path, "#{bib_id}.marc")
                  File.binwrite(path_to_file, marc_record)
                end
                batch.clear
              end
            end
          end
        end
        Rails.logger.debug("Downloaded MARC records to #{cache_path}. Took #{duration} seconds.")
      else
        Rails.logger.debug("Using cached MARC records for search (from #{cache_path}).")
      end

      # Iterate through downloaded .marc files.
      # Dir.foreach is better than Dir.glob for directories with many files.
      # Note: Dir.foreach will also include '.' and '..'

      # We need to count the files to provide an accurate total result count
      # because we might be reading from the cache rather than a new download.
      num_results = 0
      Dir.foreach(cache_path) do |entry|
        next unless entry.ends_with?('.marc')
        num_results += 1
      end

      result_counter = 0
      Dir.foreach(cache_path) do |entry|
        next unless entry.ends_with?('.marc')
        marc_file = File.join(cache_path, entry)
        begin
          # Note 1: Need to process oracle-retrieved files with UTF-8 encoding
          # (the default encoding for the MARC::Reader) in order to get
          # correctly formatted utf-8 characters. This is different than what
          # we would do if the records came from MARC-8 encoding Z39.50 responses.
          # Note 2: Marc::Reader is sometimes bad about closing files, and this
          # causes problems with NFS locks on NFS volumes, so we'll
          # read in the file and pass the content in as a StringIO.
          marc_record = MARC::Reader.new(StringIO.new(File.read(marc_file))).first
          yield marc_record, result_counter, num_results, nil
        rescue Encoding::InvalidByteSequenceError => e
          # To troubleshoot this error further, it can be useful to examine the record's text around the
          # byte range location given in the encoding error. Smart quotes are a common cause of problems.
          friendly_error_message = "CLIO record #{entry[0...-5]} has the following errors: \n\tProblem decoding characters for record in marc file #{marc_file}. This is usually caused by smart/curly quotation marks in the record (usually the abstract field), which should be replaced with plain quotation marks.  Error message: #{e.message}"
          # Log error, appending a bit of extra info
          Rails.logger.error("#{friendly_error_message}\n#{e.message}\n\t#{e.backtrace.join("\n\t")}")
          yield nil, result_counter, num_results, friendly_error_message
        end
        result_counter += 1
      end
    end

  end
end
