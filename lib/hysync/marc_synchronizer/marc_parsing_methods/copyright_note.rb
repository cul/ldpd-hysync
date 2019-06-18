module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module CopyrightNote
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_copyright_note
        end

        def add_copyright_note(marc_record, holdings_marc_records, mapping_ruleset)
          return if [
            'carnegie_scrapbooks_and_ledgers',
            'oral_history',
            'annual_reports',
            '965tibetan'
          ].include?(mapping_ruleset)

          dynamic_field_data['copyright_note'] ||= []
          dynamic_field_data['copyright_note'] << {
            'copyright_note_value' => extract_copyright_note(marc_record, mapping_ruleset)
          }
        end

        def extract_copyright_note(marc_record, mapping_ruleset)
          case mapping_ruleset
          when 'oral_history'
            field = MarcSelector.first(marc_record, 540, a: true)
            return field['a'] unless field.nil?
          else
            field = MarcSelector.first(marc_record, 542, a: true)
            return field['a'] unless field.nil?
            field = MarcSelector.first(marc_record, 540, a: true)
            return field['a'] unless field.nil?
          end
          nil
        end
      end
    end
  end
end
