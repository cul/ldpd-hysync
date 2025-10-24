module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module BiographicalNote
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_biographical_note
          end

          def add_biographical_note(marc_record, location_codes_from_holdings, mapping_ruleset)
            dynamic_field_data['note'] ||= []
            extract_biographical_notes(marc_record, mapping_ruleset).each do |biographical_note|
              dynamic_field_data['note'] << {
                'note_value' => biographical_note,
                'note_type' => 'biographical'
              }
            end
          end

          def extract_biographical_notes(marc_record, mapping_ruleset)
            MarcSelector.all(marc_record, 545, a: true).map do |field|
              field['a']
            end
          end
        end
      end
    end
  end
end
