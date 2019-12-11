module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module Note
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_note
          end

          def add_note(marc_record, holdings_marc_records, mapping_ruleset)
            dynamic_field_data['note'] ||= []
            extract_notes(marc_record, mapping_ruleset).each do |note|
              dynamic_field_data['note'] << {
                'note_value' => note
              }
            end
          end

          def extract_notes(marc_record, mapping_ruleset)
            notes = []
            MarcSelector.all(marc_record, 500, a: true).each do |field|
              notes << field['a']
            end
            MarcSelector.all(marc_record, 518, a: true).each do |field|
              note = field['a']
              note += ' ' + field['d'] if field['d']
              note += ' ' + field['o'] if field['o']
              note += ' ' + field['p'] if field['p']
              notes << StringCleaner.trailing_punctuation_and_whitespace(note)
            end
            MarcSelector.all(marc_record, 534, a: true).each do |field|
              note = field['a']
              note += ' ' + field['b'] if field['b']
              note += ' ' + field['c'] if field['c']
              note += ' ' + field['e'] if field['e']
              note += ' ' + field['f'] if field['f']
              note += ' ' + field['k'] if field['k']
              note += ' ' + field['l'] if field['l']
              note += ' ' + field['m'] if field['m']
              note += ' ' + field['n'] if field['n']
              note += ' ' + field['o'] if field['o']
              note += ' ' + field['p'] if field['p']
              notes << StringCleaner.trailing_punctuation_and_whitespace(note)
            end

            notes
          end
        end
      end
    end
  end
end
