module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module SubjectName
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_subject_name
        end

        def add_subject_name(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['subject_name'] ||= []

          subject_names_seen = Set.new
          extract_subject_names(marc_record, mapping_ruleset).each do |subject_name|
            # Keep track of seen subject names so we can deduplicate repeated ones (on a type by type basis)
            unique_subject_name_key = subject_name['subject_name_term']['name_type'] + subject_name['subject_name_term']['value']
            next if subject_names_seen.include?(unique_subject_name_key)
            subject_names_seen.add(unique_subject_name_key)
            dynamic_field_data['subject_name'] << subject_name
          end
        end

        def extract_subject_names(marc_record, mapping_ruleset)
          extract_personal_subject_names(marc_record, mapping_ruleset) +
          extract_corporate_subject_names(marc_record, mapping_ruleset) +
          extract_conference_subject_names(marc_record, mapping_ruleset)
        end

        def extract_personal_subject_names(marc_record, mapping_ruleset)
          field = 600
          name_type = 'personal'
          filters = { indicator1: 1, indicator2: 0, a: true }
          append_subfields = ['b', 'c', 'q', 'd', 'x']
          extract_fielded_subject_names(marc_record, mapping_ruleset, field, name_type, filters, append_subfields)
        end

        def extract_corporate_subject_names(marc_record, mapping_ruleset)
          field = 610
          name_type = 'corporate'
          direct_order_filters = { indicator1: 2, indicator2: 0, a: true }
          direct_order_subfields = ['b', 'c', 'd', 'x']
          direct_order_names = extract_fielded_subject_names(marc_record, mapping_ruleset, field, name_type,
                                                                       direct_order_filters, direct_order_subfields)
          jurisdiction_filters = { indicator1: 1, indicator2: 0, a: true }
          jurisdiction_subfields = ['b', 'x']
          jurisdiction_names = extract_fielded_subject_names(marc_record, mapping_ruleset, field, name_type,
                                                                       jurisdiction_filters, jurisdiction_subfields)
          direct_order_names + jurisdiction_names
        end

        def extract_conference_subject_names(marc_record, mapping_ruleset)
          field = 611
          name_type = 'conference'
          filters = { indicator1: 2, indicator2: 0, a: true }
          append_subfields = ['c', 'd', 'e', 'n', 'x']
          extract_fielded_subject_names(marc_record, mapping_ruleset, field, name_type, filters, append_subfields)
        end

        private

          def extract_fielded_subject_names(marc_record, mapping_ruleset, field, name_type, filters = {}, append_subfields = [])
            MarcSelector.all(marc_record, field, filters).map do |f|
              val = f['a']
              authority = f['2']
              uri = nil

              if authority == 'fast' && field['0'] && (fast_uri_match = field['0'].match(/^\(OCoLC\)fst(\d+)$/))
                uri = 'http://id.worldcat.org/fast/' + fast_uri_match[1]
              end

              append_subfields.each do |subfield|
                val += ' ' + f[subfield] if f[subfield]
              end
              subject_name = {
                'subject_name_term' => {
                  'value' => StringCleaner.trailing_punctuation_and_whitespace(val),
                  'name_type' => name_type,
                  'authority' => authority,
                  'uri' => uri
                }
              }
              if f['t']
                subject_name['subject_name_title_term'] = {
                  'value' => StringCleaner.trailing_punctuation_and_whitespace(f['t'])
                }
              end
              subject_name
            end
          end
      end
    end
  end
end
