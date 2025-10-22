module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Language
        include LanguageCodeMapping
        extend ActiveSupport::Concern

        included do
          register_parsing_method :add_language
        end

        def add_language(marc_record, location_codes_from_holdings, mapping_ruleset)
          dynamic_field_data['language'] ||= []
          extract_language_terms(marc_record, mapping_ruleset).each do |language_term|
            dynamic_field_data['language'] << {
              'language_term' => language_term
            }
          end
        end

        def extract_language_terms(marc_record, mapping_ruleset)
          language_codes = []
          field = MarcSelector.first(marc_record, '008')
          language_codes << field.value[35..37] unless field.nil?

          # Also look for language in 041 $a for non-oral_history records
          field = MarcSelector.first(marc_record, '041', a: true)
          language_codes << field['a'] unless field.nil?

          # Convert language codes to language terms, and also de-dupe
          language_codes.uniq.map do |language_code|
            language_value = language_code_to_language_string(language_code)
            if language_value.nil?
              self.errors << "Unmapped MARC language code for clio id #{marc_record['001'].value}: #{language_code}"
              next
            end
            {
              'value' => language_value,
              'uri' => "http://id.loc.gov/vocabulary/iso639-2/#{language_code}",
              'authority' => 'iso639-2b'
            }
          end
        end
      end
    end
  end
end
