module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module SubjectTitle
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_subject_title
        end

        def add_subject_title(marc_record, holdings_marc_records, mapping_ruleset)
          return if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'

          dynamic_field_data['subject_title'] ||= []
          extract_subject_title_terms(marc_record, mapping_ruleset).each do |subject_title_term|
            dynamic_field_data['subject_title'] << {
              'subject_title_term' => subject_title_term
            }
          end
        end

        def extract_subject_title_terms(marc_record, mapping_ruleset)
          subject_title_terms = []
          MarcSelector.all(marc_record, 630, a: true).map do |field|
            val = field['a']
            val += '--' + field['f'] if field['f']
            val += '--' + field['k'] if field['k']
            val += '--' + field['l'] if field['l']
            val += '--' + field['m'] if field['m']
            val += '--' + field['n'] if field['n']
            val += '--' + field['o'] if field['o']
            val += '--' + field['p'] if field['p']
            val += '--' + field['r'] if field['r']
            val += '--' + field['s'] if field['s']
            val += '--' + field['x'] if field['x']
            subject_title_terms << { 'value' => StringCleaner.trailing_punctuation(val) }
          end
          subject_title_terms
        end
      end
    end
  end
end
