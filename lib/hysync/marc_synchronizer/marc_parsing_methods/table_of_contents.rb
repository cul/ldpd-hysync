module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module TableOfContents
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_table_of_contents
        end

        def add_table_of_contents(marc_record, location_codes_from_holdings, mapping_ruleset)
          dynamic_field_data['table_of_contents'] ||= []
          extract_table_of_contents_values(marc_record, mapping_ruleset).each do |value|
            dynamic_field_data['table_of_contents'] << value
          end
        end

        def extract_table_of_contents_values(marc_record, mapping_ruleset)
          MarcSelector.all(marc_record, 505, a: true).map do |field|
            value = field['a']
            value += ' ' + field['g'] if field['g']
            value += ' ' + field['r'] if field['r']
            value += ' ' + field['t'] if field['t']
            value += ' ' + field['u'] if field['u']
            {
              'table_of_contents_value' => StringCleaner.trailing_punctuation_and_whitespace(value)
            }
          end
        end
      end
    end
  end
end
