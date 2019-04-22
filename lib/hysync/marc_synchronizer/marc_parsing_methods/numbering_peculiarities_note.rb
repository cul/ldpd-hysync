module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module NumberingPeculiaritiesNote
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_numbering_peculiarities_note
        end

        def add_numbering_peculiarities_note(marc_record, holdings_marc_records, mapping_ruleset)
          return unless mapping_ruleset == 'annual_reports'

          dynamic_field_data['note'] ||= []
          extract_numbering_peculiarities_notes(marc_record, mapping_ruleset).each do |note|
            dynamic_field_data['note'] << {
              'note_value' => note
            }
          end
        end

        def extract_numbering_peculiarities_notes(marc_record, mapping_ruleset)
          MarcSelector.all(marc_record, 515, a: true).map do |field|
            field['a']
          end
        end
      end
    end
  end
end
