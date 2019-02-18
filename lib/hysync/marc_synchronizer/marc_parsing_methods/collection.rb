module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Collection
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_collection
        end

        def add_collection(marc_record, holdings_marc_records, mapping_ruleset)
          terms = extract_collection_clio_ids(marc_record, mapping_ruleset).map do |clio_id|
             {
              'collection_term' => {
                'clio_id' => clio_id
              }
            }
          end
          dynamic_field_data['collection'] = terms unless terms.empty?
          add_fallback_collection(marc_record, holdings_marc_records, mapping_ruleset)
        end

        # If this marc record has a collection clio id, extract it.
        # This collection clio id, if present, will be in 773 $w and
        # will be a 7 or 8 digit number that's optionally prefixed
        # with "(NNC)".  The referenced clio record must also be a
        # collection-level record, as indicated by MARC leader byte 7
        # having a value of'c'.
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
      end
    end
  end
end