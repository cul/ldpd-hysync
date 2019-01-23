module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module AlternativeTitle
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_alternative_title
        end

        def add_alternative_title(marc_record, mapping_ruleset)
          dynamic_field_data['alternative_title'] ||= []
          dynamic_field_data['alternative_title'] << {
            'alternative_title_value' => extract_alternative_title(marc_record, mapping_ruleset)
          }
        end

        def extract_alternative_title(marc_record, mapping_ruleset)
          field = MarcSelector.first(marc_record, 246, a: true)
          return field['a'] unless field.nil?
          nil
        end
      end
    end
  end
end
