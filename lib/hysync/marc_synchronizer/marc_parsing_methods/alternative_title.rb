module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module AlternativeTitle
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_alternative_title
        end

        def add_alternative_title(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['alternative_title'] ||= []
          extract_alternative_titles(marc_record, mapping_ruleset).each do |value|
            dynamic_field_data['alternative_title'] << value
          end
        end

        def extract_alternative_titles(marc_record, mapping_ruleset)
          values = []
          MarcSelector.all(marc_record, 246, a: true).each do |field|
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['f'] if field['f']
            val += ' ' + field['g'] if field['g']
            val += ' ' + field['h'] if field['h']
            val += ' ' + field['n'] if field['n']
            val += ' ' + field['p'] if field['p']
            values << {
              'alternative_title_value' => StringCleaner.trailing_punctuation(val)
            }
          end

          # TODO: Uncomment and update code below when latest rules have been verified
          # # Additional values to extract for 965tibetan mapping
          # if mapping_ruleset == '965tibetan'
          #   primary_title_values = (
          #     MarcSelector.all(marc_record, 245, indicator1: 0, indicator2: 1, a: true) +
          #     MarcSelector.all(marc_record, 245, indicator1: 0, indicator2: 2, a: true)
          #   ).map do |field|
          #     StringCleaner.trailing_punctuation(field['a'])
          #   end
          #
          #   # Retrieve the concatenated values in subfields $a and $b for each
          #   # 880 00 or 880 10 field where the value in $6 equals 245-01 $a OR 245-02 $a
          #   (
          #     MarcSelector.all(marc_record, 880, indicator1: 0, indicator2: 0, a: true, '6': true) +
          #     MarcSelector.all(marc_record, 880, indicator1: 1, indicator2: 0, a: true, '6': true)
          #   ).each do |field|
          #     alternative_title = StringCleaner.trailing_punctuation(field['6'])
          #     if primary_title_values.include?(alternative_title)
          #       values << {
          #         'alternative_title_value' => alternative_title
          #       }
          #     end
          #   end
          # end

          values
        end
      end
    end
  end
end
