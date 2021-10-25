module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module LanguageNote
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_language_note
          end

          def add_language_note(marc_record, holdings_marc_records, mapping_ruleset)
            dynamic_field_data['note'] ||= []
            extract_language_notes(marc_record, mapping_ruleset).each do |language_note|
              dynamic_field_data['note'] << {
                'note_value' => language_note,
                'note_type' => 'language'
              }
            end
          end

          def extract_language_notes(marc_record, mapping_ruleset)
            MarcSelector.all(marc_record, 546, a: true).map do |field|
              val = field['a']
              val += ' ' + field['b'] if field['b']
              val
            end
          end
        end
      end
    end
  end
end
