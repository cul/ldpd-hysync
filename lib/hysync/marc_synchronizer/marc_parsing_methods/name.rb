module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Name
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_name
        end

        def add_name(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['name'] ||= []

          names_seen = Set.new
          extract_names(marc_record, mapping_ruleset).each do |name|
            # Keep track of seen names so we can deduplicate repeated ones (on a type by type basis)
            unique_name_key = name['name_term']['name_type'] + name['name_term']['value']
            next if names_seen.include?(unique_name_key)
            names_seen.add(unique_name_key)

            dynamic_field_data['name'] << name
          end
        end

        def extract_names(marc_record, mapping_ruleset)
          first_main_entry_name_term = extract_first_main_entry_name_term(marc_record, mapping_ruleset)

          names = (first_main_entry_name_term.present? ? [first_main_entry_name_term] : []) +
          extract_700_personal_names(marc_record, mapping_ruleset)

          if mapping_ruleset == 'ldeotechnical'
            # For ldeotechnical, we always hard-code the corporate name below
            names << {
              'name_term' => {
                'value' => 'Columbia University. Lamont-Doherty Earth Observatory',
                'name_type' => 'corporate',
                'uri' => 'temp:7f8a595bcd672d4062555333cc62fe6e64d249df79ab341a9ebdeec3425d0d8d'
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => 'Originator',
                  'uri' => 'http://id.loc.gov/vocabulary/relators/org',
                  'authority' => 'marcrelator'
                }
              }],
              'name_usage_primary' => names.blank? # This name should only be primary if there are no other names
            }
          else
            names += extract_710_corporate_names(marc_record, mapping_ruleset) + extract_711_conference_names(marc_record, mapping_ruleset)
          end
        end

        def extract_first_main_entry_name_term(marc_record, mapping_ruleset)
          # Check personal name field (100)
          field = MarcSelector.first(marc_record, 100, indicator1: 1, a: true)
          if field
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['q'] if field['q']
            val += ' ' + field['d'] if field['d']
            role_value = field['e'].present? ? field['e'] : ''
            return {
              'name_term' => {
                'value' => StringCleaner.trailing_punctuation_and_whitespace(val),
                'name_type' => 'personal',
                'uri' => field['0']
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => StringCleaner.trailing_punctuation_and_whitespace(role_value)
                  #'code' => field['4']
                }
              }],
              'name_usage_primary' => true
            }
          end

          unless mapping_ruleset == 'ldeotechnical'
            # Check corporate name field (110)
            field = MarcSelector.first(marc_record, 110, indicator1: 1, a: true) || MarcSelector.first(marc_record, 110, indicator1: 2, a: true)
            if field
              val = field['a']
              val += ' ' + field['b'] if field['b']
              val += ' ' + field['c'] if field['c']
              val += ' ' + field['d'] if field['d']
              val += ' ' + field['g'] if field['g']
              val += ' ' + field['n'] if field['n']
              role_value = field['e'].present? ? field['e'] : ''
              return {
                'name_term' => {
                  'value' => StringCleaner.trailing_punctuation_and_whitespace(val),
                  'name_type' => 'corporate',
                  'uri' => field['0']
                },
                'name_role' => [{
                  'name_role_term' => {
                    'value' => StringCleaner.trailing_punctuation_and_whitespace(role_value)
                    #'code' => field['4']
                  }
                }],
                'name_usage_primary' => true
              }
            end
          end

          # Check conference name field (111)
          field = MarcSelector.first(marc_record, 111, indicator1: 2, a: true)
          if field
            val = field['a']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['q'] if field['q']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['e'] if field['e']
            val += ' ' + field['n'] if field['n']
            role_value = field['e'].present? ? field['j'] : ''
            return {
              'name_term' => {
                'value' => StringCleaner.trailing_punctuation_and_whitespace(val),
                'name_type' => 'conference',
                'uri' => field['0']
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => StringCleaner.trailing_punctuation_and_whitespace(role_value)
                }
              }],
              'name_usage_primary' => true
            }
          end
          nil
        end

        def extract_700_personal_names(marc_record, mapping_ruleset)
          names = []
          MarcSelector.all(marc_record, 700, indicator1: 1, a: true).map do |field|
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['q'] if field['q']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['g'] if field['g']
            role_value = field['e'].present? ? field['e'] : ''
            names << {
              'name_term' => {
                'value' => StringCleaner.trailing_punctuation_and_whitespace(val),
                'name_type' => 'personal',
                'uri' => field['0']
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => StringCleaner.trailing_punctuation_and_whitespace(role_value)
                  #'code' => field['4']
                }
              }]
            }
          end

          names
        end

        def extract_710_corporate_names(marc_record, mapping_ruleset)
          names = []
          (
            MarcSelector.all(marc_record, 710, indicator1: 1, a: true) +
            MarcSelector.all(marc_record, 710, indicator1: 2, a: true)
          ).map do |field|
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['g'] if field['g']
            val += ' ' + field['n'] if field['n']
            role_value = field['e'].present? ? field['e'] : ''
            names << {
              'name_term' => {
                'value' => StringCleaner.trailing_punctuation_and_whitespace(val),
                'name_type' => 'corporate',
                'uri' => field['0']
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => StringCleaner.trailing_punctuation_and_whitespace(role_value)
                  #'code' => field['4']
                }
              }]
            }
          end

          names
        end

        def extract_711_conference_names(marc_record, mapping_ruleset)
          names = []
          MarcSelector.all(marc_record, 711, indicator1: 2, a: true).map do |field|
            val = field['a']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['q'] if field['q']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['e'] if field['e']
            val += ' ' + field['n'] if field['n']
            role_value = field['e'].present? ? field['j'] : ''
            names << {
              'name_term' => {
                'value' => StringCleaner.trailing_punctuation_and_whitespace(val),
                'name_type' => 'conference',
                'uri' => field['0']
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => StringCleaner.trailing_punctuation_and_whitespace(role_value)
                }
              }]
            }
          end

          names
        end
      end
    end
  end
end
