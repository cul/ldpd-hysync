module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module SubjectGeographic
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_subject_geographic
        end

        def add_subject_geographic(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['subject_geographic'] ||= []
          extract_subject_geographic_terms(marc_record, mapping_ruleset).each do |subject_geographic_term|
            dynamic_field_data['subject_geographic'] << {
              'subject_geographic_term' => subject_geographic_term
            }
          end
        end

        def extract_subject_geographic_terms(marc_record, mapping_ruleset)
          MarcSelector.all(marc_record, 651, indicator2: 0, a: true).map do |field|
            val = field['a']
            val += '--' + field['x'] if field['x']
            val += '--' + field['y'] if field['y']
            val += '--' + field['z'] if field['z']
            {
              'value' => StringCleaner.trailing_punctuation_and_whitespace(val),
              'authority' => 'lcsh' # always use lcsh because we're only selecting fields where indicator 2 is 0, which means authority lcsh
            }
          end
        end
      end
    end
  end
end
