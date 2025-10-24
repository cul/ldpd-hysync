module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module RightsNote
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_rights_note
          end

          def add_rights_note(marc_record, location_codes_from_holdings, mapping_ruleset)
            return unless mapping_ruleset == 'video'

            dynamic_field_data['note'] ||= []
            extract_rights_notes(marc_record, mapping_ruleset).each do |rights_note|
              dynamic_field_data['note'] << {
                'note_value' => rights_note
              }
            end
          end

          def extract_rights_notes(marc_record, mapping_ruleset)
            MarcSelector.all(marc_record, 540, a: true).map do |field|
              field['a']
            end
          end
        end
      end
    end
  end
end
