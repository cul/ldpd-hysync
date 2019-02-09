module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module SubjectName
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_subject_name
        end

        def add_subject_name(marc_record, holdings_marc_records, mapping_ruleset)
          return if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'

          dynamic_field_data['subject_name'] ||= []
          extract_subject_name_terms(marc_record, mapping_ruleset).each do |subject_name_term|
            dynamic_field_data['subject_name'] << {
              'subject_name_term' => subject_name_term
            }
          end
        end

        def extract_subject_name_terms(marc_record, mapping_ruleset)
          extract_personal_subject_name_terms(marc_record, mapping_ruleset) +
          extract_corporate_subject_name_terms(marc_record, mapping_ruleset) +
          extract_conference_subject_name_terms(marc_record, mapping_ruleset)
        end

        def extract_personal_subject_name_terms(marc_record, mapping_ruleset)
          name_terms = []
          MarcSelector.all(marc_record, 600, indicator1: 1, indicator2: 0, a: true).map do |field|
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['q'] if field['q']
            val += ' ' + field['x'] if field['x']
            name_terms << {
              'value' => StringCleaner.trailing_punctuation(val),
              'name_type' => 'personal'
            }
          end
          name_terms
        end

        def extract_corporate_subject_name_terms(marc_record, mapping_ruleset)
          name_terms = []
          MarcSelector.all(marc_record, 610, indicator1: 2, indicator2: 0, a: true).map do |field|
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['x'] if field['x']
            name_terms << {
              'value' => StringCleaner.trailing_punctuation(val),
              'name_type' => 'corporate'
            }
          end
          MarcSelector.all(marc_record, 610, indicator1: 1, indicator2: 0, a: true).map do |field|
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['x'] if field['x']
            name_terms << {
              'value' => StringCleaner.trailing_punctuation(val),
              'name_type' => 'corporate'
            }
          end
          name_terms
        end

        def extract_conference_subject_name_terms(marc_record, mapping_ruleset)
          return [] if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'
          name_terms = []
          MarcSelector.all(marc_record, 611, indicator1: 2, indicator2: 0, a: true).map do |field|
            val = field['a']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['e'] if field['e']
            val += ' ' + field['n'] if field['n']
            val += ' ' + field['x'] if field['x']
            name_terms << {
              'value' => StringCleaner.trailing_punctuation(val),
              'name_type' => 'conference'
            }
          end
          name_terms
        end
      end
    end
  end
end
