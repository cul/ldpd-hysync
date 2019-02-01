module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module PlaceOfOrigin
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_place_of_origin
        end

        def add_place_of_origin(marc_record, holdings_marc_records, mapping_ruleset)
          return if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'

          dynamic_field_data['place_of_origin'] ||= []
          dynamic_field_data['place_of_origin'] << {
            'place_of_origin_value' => extract_place_of_origin(marc_record, mapping_ruleset)
          }
        end

        def extract_place_of_origin(marc_record, mapping_ruleset)
          field = MarcSelector.first(marc_record, 260, a: true)
          return field['a'] unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 1, a: true)
          return field['a'] unless field.nil?
          nil
        end
      end
    end
  end
end
