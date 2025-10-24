module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Marc005LastModified
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_marc_005_last_modified
        end

        def add_marc_005_last_modified(marc_record, location_codes_from_holdings, mapping_ruleset)
          dynamic_field_data['marc_005_last_modified'] ||= []
          dynamic_field_data['marc_005_last_modified'] << {
            'marc_005_last_modified_value' => marc_record['005'].value
          }
        end
      end
    end
  end
end
