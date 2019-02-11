module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module BiographicalNote
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_biographical_note
        end

        def add_biographical_note(marc_record, holdings_marc_records, mapping_ruleset)
          return if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'

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
