module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      # This parsing method is only called for certain mappings,
      # and only if a collection has not already been added to
      # the record.
      module FallbackCollection
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_fallback_collection
        end

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
