module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module ClioIdentifier
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_clio_identifier
        end

        def add_clio_identifier(marc_record, location_codes_from_holdings, mapping_ruleset)
          dynamic_field_data['clio_identifier'] ||= []
          dynamic_field_data['clio_identifier'] << {
            'clio_identifier_value' => marc_record['001'].value
          }
        end
      end
    end
  end
end
