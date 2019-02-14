module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Extent
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_extent
        end

        def add_extent(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['extent'] ||= []
          dynamic_field_data['extent'] << {
            'extent_value' => extract_extent(marc_record, mapping_ruleset)
          }
        end

        def extract_extent(marc_record, mapping_ruleset)
          values = []
          MarcSelector.all(marc_record, 300, a: true).each do |field|
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val += ' ' + field['c'] if field['c']
            val += ' ' + field['f'] if field['f']
            values << StringCleaner.trailing_punctuation(val)
          end
          values.join('; ')
        end
      end
    end
  end
end
