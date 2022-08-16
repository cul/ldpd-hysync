module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module LocalIdentifier
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_local_identifier
        end

        def add_local_identifier(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['local_identifier'] ||= []

          MarcSelector.all(marc_record, '024', indicator2: 8, a: true).each do |field|
            dynamic_field_data['local_identifier'] << {
              'local_identifier_value' => StringCleaner.trailing_punctuation_and_whitespace(field['a'])
            }
          end
        end
      end
    end
  end
end
