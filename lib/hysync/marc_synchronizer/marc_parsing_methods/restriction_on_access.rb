module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module RestrictionOnAccess
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_restriction_on_access
        end

        def add_restriction_on_access(marc_record, mapping_ruleset)
          dynamic_field_data['restriction_on_access'] ||= []
          dynamic_field_data['restriction_on_access'] << {
            'restriction_on_access_value' => extract_restriction_on_access(marc_record, mapping_ruleset),
          }
        end

        def extract_restriction_on_access(marc_record, mapping_ruleset)
          field = MarcSelector.first(marc_record, '506', a: true)
          return field['a'] if field
          nil
        end
      end
    end
  end
end
