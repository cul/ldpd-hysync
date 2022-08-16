module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module StatementOfResponsibilityNote
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_statement_of_responsibility_note
          end

          def add_statement_of_responsibility_note(marc_record, holdings_marc_records, mapping_ruleset)
            return unless mapping_ruleset == 'NPF'

            dynamic_field_data['note'] ||= []

            MarcSelector.all(marc_record, 245, c: true).map do |field|
              dynamic_field_data['note'] << {
                'note_value' => field['c'],
                'note_type' => 'statement of responsibility'
              }
            end
          end
        end
      end
    end
  end
end
