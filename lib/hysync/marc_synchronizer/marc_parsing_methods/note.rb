module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Note
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_note
        end

        def add_note(marc_record, mapping_ruleset)
          dynamic_field_data['note'] ||= []
          extract_notes(marc_record, mapping_ruleset).each do |note|
            dynamic_field_data['note'] << {
              'note_value' => note
            }
          end
        end

        def extract_notes(marc_record, mapping_ruleset)
          MarcSelector.all(marc_record, 500, a: true).map do |field|
            field['a']
          end
        end
      end
    end
  end
end
