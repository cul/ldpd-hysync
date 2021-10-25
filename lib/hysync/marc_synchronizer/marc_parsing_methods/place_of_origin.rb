module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module PlaceOfOrigin
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_place_of_origin
        end

        def add_place_of_origin(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['place_of_origin'] ||= []
          dynamic_field_data['place_of_origin'] << {
            'place_of_origin_value' => StringCleaner.trailing_punctuation_and_whitespace(
              extract_place_of_origin(marc_record, mapping_ruleset)
            )
          }
        end

        def extract_place_of_origin(marc_record, mapping_ruleset)
          if mapping_ruleset == 'NPF'
            values_to_concatenate = []
            part1_field = MarcSelector.first(marc_record, 264, indicator2: 1, a: /^((?!not identified).)*$/) # ignore if 'a' value contains 'not identified'
            part2_field = MarcSelector.first(marc_record, 880, '6': /^264-/, a: /^((?!not identified).)*$/) # ignore if 'a' value contains 'not identified'
            values_to_concatenate << StringCleaner.trailing_punctuation_and_whitespace(part1_field['a']) unless part1_field.nil?
            values_to_concatenate << StringCleaner.trailing_punctuation_and_whitespace(part2_field['a']) unless part2_field.nil?
            return values_to_concatenate.join(' = ') unless values_to_concatenate.blank?
            return nil
          end

          field = MarcSelector.first(marc_record, 260, a: true)
          return field['a'] unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 1, a: true)
          return field['a'] unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 0, a: true)
          return field['a'] unless field.nil?
          field = MarcSelector.first(marc_record, 264, indicator2: 3, a: true)
          return field['a'] unless field.nil?
          nil
        end
      end
    end
  end
end
