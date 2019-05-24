module Voyager
  module ClientBehavior
    module HoldingsRetrieval
      extend ActiveSupport::Concern

      ORACLE_WAIT_TIMEOUT = 10.seconds

      def holdings_for_bib_id(bib_id)
        # Clear cached results if we don't want to use cached results
        clear_holdings_cache(bib_id) if !@z3950_config['use_cached_results']
        cache_path = holdings_cache_path(bib_id)

        if !holdings_cache_exists?(bib_id)
          FileUtils.mkdir_p(cache_path)
          duration = Benchmark.realtime do
            retrieve_holdings(bib_id).each do |holding_id, holding_marc|
              path_to_file = File.join(cache_path, "#{holding_id}.marc")
              File.binwrite(path_to_file, holding_marc)
            end
          end
          Rails.logger.debug("Downloaded holdings to #{cache_path}. Took #{duration} seconds.")
        else
          Rails.logger.debug("Using cached holdings for record (from #{cache_path}).")
        end

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
            # we're doing over Z39.50, where we want to use MARC-8 instead.
            # Note 2: Marc::Reader is sometimes bad about closing files, and this
            # causes problems with NFS locks on NFS volumes, so we'll
            # read in the file and pass the content in as a StringIO.
            holdings_marc_record = MARC::Reader.new(StringIO.new(File.read(marc_file))).first
            yield holdings_marc_record, result_counter, num_results
          rescue Encoding::InvalidByteSequenceError => e
            # Re-raise error, appending a bit of extra info
            raise e, "Problem decoding characters for holdings marc file #{marc_file}. Error message: #{$!}", $!.backtrace
            # To troubleshoot this error further, it can be useful to examine the record's text around the
            # byte range location given in the encoding error. Smart quotes are a common cause of problems.
          end
          result_counter += 1
        end
      end

      def clear_holdings_cache(bib_id)
        path = holdings_cache_path(bib_id)
        FileUtils.rm_rf(path)
        if File.exists?(path)
          Rails.logger.error "Tried to delete holdings cache at #{path}, but it still exists! Maybe an NFS lock issue?"
        end
      end

      def holdings_cache_exists?(bib_id)
        File.exists?(holdings_cache_path(bib_id))
      end

      def holdings_cache_path(bib_id)
        Rails.root.join('tmp', 'holdings_cache', bib_id)
      end

      def retrieve_holdings(bib_id)
        results = execute_select_command_with_retry(fill_in_query_placeholders("select MFHD_ID from bib_mfhd where bib_id = ~bibid~", bibid: bib_id))

        holdings_keys = []
        results.each do |result|
          holdings_keys << result['MFHD_ID']
        end

        holdings_ids_to_records = {}

        holdings_keys.each do |holdings_key|
          holdings_ids_to_records[holdings_key] ||= ''
          results = execute_select_command_with_retry(fill_in_query_placeholders("select RECORD_SEGMENT from mfhd_data where mfhd_id = ~bibid~ order by seqnum", bibid: bib_id))
          results.each do |result|
            holdings_ids_to_records[holdings_key] += result['RECORD_SEGMENT']
          end
        end

        holdings_ids_to_records
      end
    end
  end
end
