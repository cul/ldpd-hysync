module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module PublishTargets
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_publish_targets
        end

        MAP_965_TO_PUBLISH_TARGET = {
          '965carnegiedpf' => 'carnegie_staging'
        }.freeze

        def add_publish_targets(marc_record, holdings_marc_records, mapping_ruleset)
          # TODO: Use publish_to for Hyacinth 3

          publish_target_string_keys = []
          marc_record.fields('965').each do |field|
            publish_target_string_key = MAP_965_TO_PUBLISH_TARGET[field['a']]
            next if publish_target_string_key.blank?
            publish_target_string_keys << publish_target_string_key
          end

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
