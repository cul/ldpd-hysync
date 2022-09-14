# frozen_string_literal: true

module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Notes
        module OriginalLocationNote
          extend ActiveSupport::Concern
          included do
            register_parsing_method :add_original_location_note
          end

          def add_original_location_note(marc_record, _holdings_marc_records, mapping_ruleset)
            return unless mapping_ruleset == 'NPF'

            dynamic_field_data['note'] ||= []

            MarcSelector.all(marc_record, 535, indicator1: 1, a: true).map do |field|
              dynamic_field_data['note'] << {
                'note_value' => field['a'],
                'note_type' => 'original location'
              }
            end
          end
        end
      end
    end
  end
end
