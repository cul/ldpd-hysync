module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module PublishTargets
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_publish_targets_based_on_project
        end

        def add_publish_targets_based_on_project(marc_record, location_codes_from_holdings, mapping_ruleset)
          project_string_key = digital_object_data.fetch('project', nil)&.fetch('string_key', nil)&.to_sym
          return if project_string_key.nil?

          publish_target_string_keys = Array.wrap(HYSYNC[:publish_target_mappings][project_string_key])
          return if publish_target_string_keys.blank?

          digital_object_data['publish_targets'] ||= []
          publish_target_string_keys.each do |publish_target_string_key|
            digital_object_data['publish_targets'] << {
              'string_key' => publish_target_string_key
            }
          end
        end
      end
    end
  end
end
