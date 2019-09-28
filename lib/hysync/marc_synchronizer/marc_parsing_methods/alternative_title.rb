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

          # Additional rules for 965tibetan
          if mapping_ruleset == '965tibetan'
            # MarcSelector.all(marc_record, 880, indicator1: 0, indicator2: 0, '6': true).each do |field|
            #   values << {
            #     'alternative_title_value' => StringCleaner.trailing_punctuation(field['6'])
            #   }
            # end
            #
            # MarcSelector.all(marc_record, 245, indicator1: 0, indicator2: 1, a: true).each do |field|
            #   values << {
            #     'alternative_title_value' => StringCleaner.trailing_punctuation(field['6'])
            #   }
            # end
          end

          values
        end
      end
    end
  end
end
