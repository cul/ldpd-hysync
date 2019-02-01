module Voyager
  module ClientBehavior
    module BibRecordRetrieval
      extend ActiveSupport::Concern

      # Finds a single record by bib id
      # @return [MARC::Record] The MARC record associated with the given id.
      def find_by_bib_id(bib_id)

        # Clear cached results if we don't want to use cached results
        clear_bib_cache(bib_id) if !@z3950_config['use_cached_results']
        cache_path = bib_cache_path(bib_id)

        if !bib_cache_exists?(bib_id)
          FileUtils.mkdir_p(File.dirname(cache_path))
          duration = Benchmark.realtime do
            File.binwrite(cache_path, retrieve_bib_marc(bib_id))
          end
          Rails.logger.debug("Downloaded bib to #{cache_path}. Took #{duration} seconds.")
        else
          Rails.logger.debug("Using cached bib for record (from #{cache_path}).")
        end

        begin
          # Need to process the file with MARC-8 external encoding in order to get correctly formatted utf-8 characters
          bib_marc_record = MARC::Reader.new(cache_path, :external_encoding => 'MARC-8').first
          return bib_marc_record
        rescue Encoding::InvalidByteSequenceError => e
          if @z3950_config['raise_error_when_marc_decode_fails']
            # Re-raise error, appending a bit of extra info
            raise e, "Problem decoding characters for record in marc file #{marc_file}. Error message: #{$!}", $!.backtrace
            # To troubleshoot this error further, it can be useful to examine the record's text around the
            # byte range location given in the encoding error. Smart quotes are a common cause of problems.
          else
            Rails.logger.warn "Skipping marc file #{marc_file} because of a decoding error."
          end
        end
        nil
      end

      def clear_bib_cache(bib_id)
        FileUtils.rm_rf(bib_cache_path(bib_id))
      end

      def bib_cache_exists?(bib_id)
        File.exists?(bib_cache_path(bib_id))
      end

      def bib_cache_path(bib_id)
        Rails.root.join('tmp', 'bib_cache', bib_id + '.marc').to_s
      end

      def retrieve_bib_marc(bib_id)
        results = execute_select_command(fill_in_query_placeholders("select RECORD_SEGMENT from bib_data where bib_id = ~bibid~ order by seqnum", bibid: bib_id))
        bib_marc = ''
        results.each do |result|
          bib_marc += result['RECORD_SEGMENT']
        end
        bib_marc
      end
    end
  end
end
