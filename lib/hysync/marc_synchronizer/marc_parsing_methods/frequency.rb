module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Frequency
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_frequency
        end

        def add_frequency(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['frequency'] ||= []
          extract_frequency_terms(marc_record, mapping_ruleset).each do |frequency_term|
            dynamic_field_data['frequency'] << {
              'frequency_term' => frequency_term
            }
          end
        end

        def extract_frequency_terms(marc_record, mapping_ruleset)
          frequency_terms = []

          (
            MarcSelector.all(marc_record, '310', a: true) +
            MarcSelector.all(marc_record, '321', a: true)
          ).each do |field|
            frequency_terms << {
              'value' => StringCleaner.trailing_punctuation_and_whitespace(field['a'] + (field['b'] ? ' ' + field['b'] : ''))
            }
          end

          frequency_terms
        end
      end
    end
  end
end
