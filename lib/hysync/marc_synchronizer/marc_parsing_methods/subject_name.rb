module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module SubjectName
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_subject_name
        end

        NO_VALUES = [].freeze

        def add_subject_name(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['subject_name'] ||= []
          extract_subject_name_terms(marc_record, mapping_ruleset).each do |subject_name_term|
            subject_title = subject_name_term.delete('subject_name_title_term')
            name_subject = {
              'subject_name_term' => subject_name_term
            }
            name_subject['subject_name_title_term'] = subject_title if subject_title
            dynamic_field_data['subject_name'] << name_subject
          end
        end

        def extract_subject_name_terms(marc_record, mapping_ruleset)
          extract_personal_subject_name_terms(marc_record, mapping_ruleset) +
          extract_corporate_subject_name_terms(marc_record, mapping_ruleset) +
          extract_conference_subject_name_terms(marc_record, mapping_ruleset)
        end

        def extract_personal_subject_name_terms(marc_record, mapping_ruleset)
          name_terms = []
          field = 600
          name_type = 'personal'
          filters = { indicator1: 1, indicator2: 0, a: true }
          append_subfields = ['b', 'c', 'd', 'q', 'x']
          extract_fielded_subject_name_terms(marc_record, mapping_ruleset, field, name_type, filters, append_subfields)
        end

        def extract_corporate_subject_name_terms(marc_record, mapping_ruleset)
          name_terms_direct = []
          field = 610
          name_type = 'corporate'
          direct_order_filters = { indicator1: 2, indicator2: 0, a: true }
          direct_order_subfields = ['b', 'c', 'd', 'x']
          direct_order_name_terms = extract_fielded_subject_name_terms(marc_record, mapping_ruleset, field, name_type,
                                                                       direct_order_filters, direct_order_subfields)
          jurisdiction_filters = { indicator1: 1, indicator2: 0, a: true }
          jurisdiction_subfields = ['b', 'x']
          jurisdiction_name_terms = extract_fielded_subject_name_terms(marc_record, mapping_ruleset, field, name_type,
                                                                       jurisdiction_filters, jurisdiction_subfields)
          direct_order_name_terms + jurisdiction_name_terms
        end

        def extract_conference_subject_name_terms(marc_record, mapping_ruleset)
          return NO_VALUES if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'
          field = 611
          name_type = 'conference'
          filters = { indicator1: 2, indicator2: 0, a: true }
          append_subfields = ['c', 'd', 'e', 'n', 'x']
          extract_fielded_subject_name_terms(marc_record, mapping_ruleset, field, name_type, filters, append_subfields)
        end

        private

          def extract_fielded_subject_name_terms(marc_record, mapping_ruleset, field, name_type, filters = {}, append_subfields = [])
            name_terms = []
            MarcSelector.all(marc_record, field, filters).map do |field|
              val = field['a']
              append_subfields.each do |subfield|
                val += ' ' + field[subfield] if field[subfield]
              end
              name_term = {
                'value' => StringCleaner.trailing_punctuation(val),
                'name_type' => name_type
              }
              if field['t']
                name_term['subject_name_title_term'] = {
                  'value' => StringCleaner.trailing_punctuation(field['t'])
                }
              end
              name_terms << name_term
            end
            name_terms
          end

      end
    end
  end
end
