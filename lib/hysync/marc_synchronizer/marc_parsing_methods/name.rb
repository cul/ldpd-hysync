module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Name
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_name
        end

        def add_name(marc_record, holdings_marc_records, mapping_ruleset)
          return if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'

          dynamic_field_data['name'] ||= []
          extract_names(marc_record, mapping_ruleset).each do |name|
            dynamic_field_data['name'] << name
          end
        end

        def extract_names(marc_record, mapping_ruleset)
          first_main_entry_name_term = extract_first_main_entry_name_term(marc_record, mapping_ruleset)

          (first_main_entry_name_term.present? ? [first_main_entry_name_term] : []) +
          extract_700_personal_names(marc_record, mapping_ruleset) +
          extract_710_corporate_names(marc_record, mapping_ruleset) +
          extract_711_conference_names(marc_record, mapping_ruleset)
        end

        def extract_first_main_entry_name_term(marc_record, mapping_ruleset)
          # Check personal name field (100)
          field = MarcSelector.first(marc_record, 100, indicator1: 1, a: true)
          if field
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['q'] if field['q']
            return {
              'name_term' => {
                'value' => clean_name(val),
                'name_type' => 'personal'
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => clean_name_role(field['e'])
                  #'code' => field['4']
                }
              }],
              'name_usage_primary' => true
            }
          end
          # Check corporate name field (110)
          field = MarcSelector.first(marc_record, 100, indicator1: 1, a: true) || MarcSelector.first(marc_record, 100, indicator1: 2, a: true)
          if field
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['g'] if field['g']
            val += ' ' + field['n'] if field['n']
            return {
              'name_term' => {
                'value' => clean_name(val),
                'name_type' => 'corporate'
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => clean_name_role(field['e'])
                  #'code' => field['4']
                }
              }],
              'name_usage_primary' => true
            }
          end
          # Check conference name field (111)
          field = MarcSelector.first(marc_record, 111, indicator1: 2, a: true)
          if field
            val = field['a']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['e'] if field['e']
            val += ' ' + field['n'] if field['n']
            val += ' ' + field['q'] if field['q']
            return {
              'name_term' => {
                'value' => clean_name(val),
                'name_type' => 'conference'
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => clean_name_role(field['j'])
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
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['g'] if field['g']
            val += ' ' + field['q'] if field['q']
            names << {
              'name_term' => {
                'value' => clean_name(val),
                'name_type' => 'personal'
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => clean_name_role(field['e'])
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
            names << {
              'name_term' => {
                'value' => clean_name(val),
                'name_type' => 'corporate'
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => clean_name_role(field['e'])
                  #'code' => field['4']
                }
              }]
            }
          end
          names
        end

        def extract_711_conference_names(marc_record, mapping_ruleset)
          return [] if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'
          names = []
          MarcSelector.all(marc_record, 711, indicator1: 2, a: true).map do |field|
            val = field['a']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['d'] if field['d']
            val += ' ' + field['e'] if field['e']
            val += ' ' + field['n'] if field['n']
            val += ' ' + field['q'] if field['q']
            names << {
              'name_term' => {
                'value' => clean_name(val),
                'name_type' => 'conference'
              },
              'name_role' => [{
                'name_role_term' => {
                  'value' => clean_name_role(field['j'])
                }
              }]
            }
          end
          names
        end

        def clean_name_role(name_role)
          return nil if name_role.nil?
          name_role.sub(/[.,]$/, '') # remove trailing period or comma if present
        end

        def clean_name(name)
          return nil if name.nil?
          name.sub(/,$/, '') # remove trailing comma if present
        end
      end
    end
  end
end
