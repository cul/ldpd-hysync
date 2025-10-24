module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module ProvenanceNote
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_provenance_note
          end

          def add_provenance_note(marc_record, location_codes_from_holdings, mapping_ruleset)
            return if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'

            dynamic_field_data['note'] ||= []
            dynamic_field_data['note'] += extract_provenance_note(marc_record, mapping_ruleset)
          end

          def extract_provenance_note(marc_record, mapping_ruleset)
            MarcSelector.all(marc_record, 541, a: true).map do |field|
              {
                'note_value' => MarcSelector.concat_subfield_values(field, ['a', 'b', 'c', 'd', 'e', 'f', 'h', 'n', 'o', '3']),
                'note_type' => 'provenance'
              }
            end
          end
        end
      end
    end
  end
end
