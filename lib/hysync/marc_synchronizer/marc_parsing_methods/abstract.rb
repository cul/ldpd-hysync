module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Abstract
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_abstract
        end

        def add_abstract(marc_record, location_codes_from_holdings, mapping_ruleset)
          dynamic_field_data['abstract'] ||= []
          dynamic_field_data['abstract'] << {
            'abstract_value' => extract_abstract(marc_record, mapping_ruleset)
          }
        end

        def extract_abstract(marc_record, mapping_ruleset)
          fields = MarcSelector.all(marc_record, 520, a: true)
          return nil if fields.length == 0
          fields.map do |field|
            val = field['a']
            val += ' ' + field['b'] if field['b']
            val
          end.join("\n\n")
        end

      end
    end
  end
end
