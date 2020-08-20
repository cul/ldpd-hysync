module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module AlternativeTitle
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_alternative_title
        end

        def add_alternative_title(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['alternative_title'] ||= []
          extract_alternative_titles(marc_record, mapping_ruleset).each do |value|
            dynamic_field_data['alternative_title'] << value
          end
        end

        def extract_alternative_titles(marc_record, mapping_ruleset)
          values = []

          MarcSelector.all(marc_record, 246, a: true).each do |field|
            values << {
              'alternative_title_value' => MarcSelector.concat_subfield_values(field, ['a', 'b', 'f', 'g', 'h', 'n', 'p'])
            }
          end

          # Also retrieve 880 $a $b -- but ONLY when an 880 field has a $6 value that starts with "245-" or "246-" (e.g. "245-01", "246-01", "246-02", etc.)
          (
            MarcSelector.all(marc_record, 880, indicator1: 0, indicator2: 0, a: true, '6': true) +
            MarcSelector.all(marc_record, 880, indicator1: 1, indicator2: 0, a: true, '6': true)
          ).each do |field|
            next unless field['6'].start_with?('245-') || field['6'].start_with?('246-')
            values << {
              'alternative_title_value' => MarcSelector.concat_subfield_values(field, ['a', 'b'])
            }
          end

          values
        end
      end
    end
  end
end
