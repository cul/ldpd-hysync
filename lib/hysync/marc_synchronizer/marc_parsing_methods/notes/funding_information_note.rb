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
            MarcSelector.all(marc_record, 536, a: true).map do |field|
              MarcSelector.concat_subfield_values(field, ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'])
            end
          end
        end
      end
    end
  end
end
