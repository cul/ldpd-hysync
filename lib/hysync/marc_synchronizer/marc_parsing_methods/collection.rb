module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Collection
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_collection
        end

        def add_collection(marc_record, holdings_marc_records, mapping_ruleset)
          if mapping_ruleset == "annual_reports"
            dynamic_field_data['collection'] = [{
              'collection_term' => {
                'value' => 'Carnegie Corporation of New York Records',
                'uri' => 'http://id.library.columbia.edu/term/72fcfd07-f7db-4a18-bdb2-beb0abce071c'
              }
            }]
            return
          end

          terms = extract_collection_clio_ids(marc_record, mapping_ruleset).map do |clio_id|
             {
              'collection_term' => {
                'clio_id' => clio_id
              }
            }
          end
          dynamic_field_data['collection'] = terms unless terms.empty?
          add_fallback_collection(marc_record, holdings_marc_records, mapping_ruleset)

          add_archival_series_to_first_collection_if_present(marc_record, mapping_ruleset)
        end

        # If this marc record has a collection clio id, extract it.
        # This collection clio id, if present, will be in 773 $w and
        # will be a 7 or 8 digit number that's optionally prefixed
        # with "(NNC)".
        def extract_collection_clio_ids(marc_record, mapping_ruleset)
          clio_ids = []
          collection_field_773 = MarcSelector.first(marc_record, 773, w: true)
          if collection_field_773
            match = collection_field_773['w'].match(/^(\(NNC\))*(\d{7,8})$/)
            # If 773 $w doesn't match our record, this isn't a valid CLIO id reference
            clio_ids << match[2] # retrieve numeric portion of ID
          end
          clio_ids
        end

        # This parsing method is only called for certain mappings,
        # and only if a collection has not already been added to
        # the record.
        def add_fallback_collection(marc_record, holdings_marc_records, mapping_ruleset)
          return unless dynamic_field_data['collection'].nil?
          dynamic_field_data['collection'] ||= []
          dynamic_field_data['collection'] << {
            'collection_term' => {
              'value' => extract_fallback_collection(marc_record, mapping_ruleset)
            }
          }
        end

        def extract_fallback_collection(marc_record, mapping_ruleset)
          field = MarcSelector.first(marc_record, 710, indicator1: 2, a: true, '5': 'NNC')
          return field['a'] unless field.nil?
        end

        def add_archival_series_to_first_collection_if_present(marc_record, mapping_ruleset)
          if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers' && dynamic_field_data['collection'].length > 0
            field = MarcSelector.first(marc_record, 773, indicator1: 0, g: true)
            return unless field
            dynamic_field_data['collection'].first['collection_archival_series'] = [
              {
                'collection_archival_series_part' => [
                  {
                    'collection_archival_series_part_type' => 'series',
                    'collection_archival_series_part_level' => 1,
                    'collection_archival_series_part_title' => field['g']
                  }
                ]
              }
            ]
          end
        end
      end
    end
  end
end
