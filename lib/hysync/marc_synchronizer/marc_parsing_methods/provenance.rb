module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Provenance
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_provenance
        end

        def add_provenance(marc_record, holdings_marc_records, mapping_ruleset)
          return if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'

          dynamic_field_data['note'] ||= []
          dynamic_field_data['note'] << extract_provenance_note(marc_record, mapping_ruleset)
        end

        def extract_provenance_note(marc_record, mapping_ruleset)
          field = MarcSelector.first(marc_record, 541, a: true)
          return nil unless field

          value = field['a']
          value += ' ' + field['b'] if field['b']
          value += ' ' + field['c'] if field['c']
          value += ' ' + field['d'] if field['d']
          value += ' ' + field['e'] if field['e']
          value += ' ' + field['f'] if field['f']
          value += ' ' + field['h'] if field['h']
          value += ' ' + field['n'] if field['n']
          value += ' ' + field['o'] if field['o']
          value += ' ' + field['3'] if field['3']

          {
            'note_value' => value,
            'note_type' => 'Provenance'
          }
        end
      end
    end
  end
end
