module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Publisher
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_publisher
        end

        def add_publisher(marc_record, holdings_marc_records, mapping_ruleset)
          return if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'

          dynamic_field_data['publisher'] ||= []
          dynamic_field_data['publisher'] << {
            'publisher_value' => StringCleaner.trailing_punctuation_and_whitespace(
              extract_publisher(marc_record, mapping_ruleset)
            )
          }
        end

        def extract_publisher(marc_record, mapping_ruleset)
          field = MarcSelector.first(marc_record, 260, b: true)
          return field['b'] unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 1, b: true)
          return field['b'] unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 0, b: true)
          return field['b'] unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 3, b: true)
          return field['b'] unless field.nil?
          nil
        end
      end
    end
  end
end
