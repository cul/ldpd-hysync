module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module ActionNote
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_action_note
          end

          def add_action_note(marc_record, holdings_marc_records, mapping_ruleset)
            dynamic_field_data['internal_note'] ||= []
            extract_action_notes(marc_record, mapping_ruleset).each do |action_note|
              dynamic_field_data['internal_note'] << {
                'internal_note_value' => action_note
              }
            end
          end

          def extract_action_notes(marc_record, mapping_ruleset)
            MarcSelector.all(marc_record, 583, indicator1: 0, a: true).map do |field|
              note = field['a']
              note += ' ' + field['b'] if field['b']
              note += ' ' + field['c'] if field['c']
              note += ' ' + field['d'] if field['d']
              note += ' ' + field['e'] if field['e']
              note += ' ' + field['f'] if field['f']
              note += ' ' + field['h'] if field['h']
              note += ' ' + field['i'] if field['i']
              note += ' ' + field['j'] if field['j']
              note += ' ' + field['k'] if field['k']
              note += ' ' + field['l'] if field['l']
              note += ' ' + field['n'] if field['n']
              note += ' ' + field['o'] if field['o']
              note += ' ' + field['x'] if field['x']
              StringCleaner.trailing_punctuation_and_whitespace(note)
            end
          end
        end
      end
    end
  end
end
