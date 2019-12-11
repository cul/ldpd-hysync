module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module FundingInformationNote
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_funding_information_note
          end

          def add_funding_information_note(marc_record, holdings_marc_records, mapping_ruleset)
            dynamic_field_data['note'] ||= []
            extract_funding_information_notes(marc_record, mapping_ruleset).each do |note|
              dynamic_field_data['note'] << {
                'note_value' => note,
                'note_type' => 'funding'
              }
            end
          end

          def extract_funding_information_notes(marc_record, mapping_ruleset)
            notes = []
            MarcSelector.all(marc_record, 536, a: true).each do |field|
              note = field['a']
              note += ' ' + field['b'] if field['b']
              note += ' ' + field['c'] if field['c']
              note += ' ' + field['d'] if field['d']
              note += ' ' + field['e'] if field['e']
              note += ' ' + field['f'] if field['f']
              note += ' ' + field['g'] if field['g']
              note += ' ' + field['h'] if field['h']
              notes << StringCleaner.trailing_punctuation_and_whitespace(note)
            end
            notes
          end
        end
      end
    end
  end
end
