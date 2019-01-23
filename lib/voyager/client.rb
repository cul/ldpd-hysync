module Voyager
  class Client
    REQUIRED_CONFIG_OPTS = ['url', 'port', 'database_name'].freeze
    def initialize(config)
      @z3950_config = config['z3950']
      # The ZOOM library has a bug where if the supplied url argument is nil,
      # the native, backing yaz library throws an error that can't be caught
      # by ruby, so we need to ensure that config['url'] is never nil. And as
      # long as we're checking for url, we'll check for other required config
      # options too.
      REQUIRED_CONFIG_OPTS.each do |required_config_opt|
        raise ArgumentError, "Missing config['#{required_config_opt}'] for #{self.class}" unless @z3950_config[required_config_opt].present?
      end
    end

    # Finds a single record by bib id
    # @return [MARC::Record] The MARC record associated with the given id.
    def find_by_bib_id(bib_id)
      search(1, 7, bib_id) do |marc_record, _i, _num_results|
        return marc_record
      end
      nil
    end

    # Finds a single record by bib id
    # @return [MARC::Record] The MARC record associated with the given id.
    def search_by_965_value(string_965_value)
      search(1, 9000, string_965_value) do |marc_record, i, num_results|
        yield marc_record, i, num_results
      end
    end

    def clear_cache(query_type, query_field, query_value)
      FileUtils.rm_rf(cache_path(query_type, query_field, query_value))
    end

    def cache_exists?(query_type, query_field, query_value)
      File.exists?(cache_path(query_type, query_field, query_value))
    end

    def cache_path(query_type, query_field, query_value)
      Rails.root.join('tmp', 'z3950_cache', "#{query_type}-#{query_field}-#{query_value}")
    end

    # @param record [ZOOM::Record]
    def bib_id_for_zoom_record(record)
      MARC::Record.new_from_marc(record.raw)['001'].value
    end

    def search(query_type, query_field, query_value)
      # Clear cached results if we don't want to use cached results
      clear_cache(query_type, query_field, query_value) if !@z3950_config['use_cached_results']
      cache_path_for_search = cache_path(query_type, query_field, query_value)

      if !cache_exists?(query_type, query_field, query_value)
        FileUtils.mkdir_p(cache_path_for_search)
        duration = Benchmark.realtime do
          ZOOM::Connection.open(@z3950_config['url'], @z3950_config['port']) do |conn|
            conn.database_name = @z3950_config['database_name']
            conn.preferred_record_syntax = 'USMARC'
            result_set = conn.search("@attr #{query_type}=#{query_field} #{query_value}")
            for i in 0..(result_set.length - 1) do
              bib_id = bib_id_for_zoom_record(result_set[i])
              path_to_file = File.join(cache_path_for_search, "#{bib_id}.marc")
              File.binwrite(path_to_file, result_set[i].raw)
            end
          end
        end
        Rails.logger.debug("Downloaded MARC records to #{cache_path_for_search}. Took #{duration} seconds.")
      else
        Rails.logger.debug("Using cached MARC records for search (from #{cache_path_for_search}).")
      end

      # Iterate through downloaded .marc files.
      # Dir.foreach is better than Dir.glob for directories with many files.
      # Note: Dir.foreach will also include '.' and '..'

      # We need to count the files to provide an accurate total result count
      # because we might be reading from the cache rather than a new download.
      num_results = 0
      Dir.foreach(cache_path_for_search) do |entry|
        next unless entry.ends_with?('.marc')
        num_results += 1
      end

      result_counter = 0
      Dir.foreach(cache_path_for_search) do |entry|
        next unless entry.ends_with?('.marc')
        marc_file = File.join(cache_path_for_search, entry)
        begin
          # Need to process the file with MARC-8 external encoding in order to get correctly formatted utf-8 characters
          marc_record = MARC::Reader.new(marc_file, :external_encoding => 'MARC-8').first
          yield marc_record, result_counter, num_results
        rescue Encoding::InvalidByteSequenceError => e
          if @z3950_config['raise_error_when_marc_decode_fails']
            # Re-raise error, appending a bit of extra info
            raise e, "Problem decoding characters for record in marc file #{marc_file}. Error message: #{$!}", $!.backtrace
            # To troubleshoot this error further, it can be useful to examine the record's text around the
            # byte range location given in the encoding error. Smart quotes are a common cause of problems.
          else
            Rails.logger.warn "Skipping marc file #{marc_file} because of a decoding error."
            next
          end
        end
        result_counter += 1
      end
    end

  end
end
