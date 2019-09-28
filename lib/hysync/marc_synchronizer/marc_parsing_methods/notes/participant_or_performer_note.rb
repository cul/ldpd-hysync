module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module ParticipantOrPerformerNote
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_participant_or_performer_note
          end

          def add_participant_or_performer_note(marc_record, holdings_marc_records, mapping_ruleset)
            dynamic_field_data['note'] ||= []
            extract_participant_or_performer_notes(marc_record, mapping_ruleset).each do |note|
              dynamic_field_data['note'] << {
                'note_value' => note,
                'note_type' => 'performers'
              }
            end
          end

          def extract_participant_or_performer_notes(marc_record, mapping_ruleset)
            MarcSelector.all(marc_record, 511, a: true).map do |field|
              field['a']
            end
          end
        end
      end
    end
  end
end
