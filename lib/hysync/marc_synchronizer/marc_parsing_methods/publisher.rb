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
          if mapping_ruleset == 'NPF'
            values_to_concatenate = []
            part1_field = MarcSelector.first(marc_record, 264, indicator2: 1, b: /^((?!not identified).)*$/) # ignore if 'b' value contains 'not identified'
            part2_field = MarcSelector.first(marc_record, 880, '6': /^264-/, b: /^((?!not identified).)*$/) # ignore if 'b' value contains 'not identified'
            values_to_concatenate << StringCleaner.trailing_punctuation_and_whitespace(part1_field['b']) unless part1_field.nil?
            values_to_concatenate << StringCleaner.trailing_punctuation_and_whitespace(part2_field['b']) unless part2_field.nil?
            return values_to_concatenate.join(' = ') unless values_to_concatenate.blank?
            return nil
          end

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
