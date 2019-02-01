module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Project
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_project
        end

        MAP_965_TO_PROJECT = {
          '965carnegiedpf' => 'carnegie_dpf',
          '965TBM' => 'TBM'
        }.freeze

        def add_project(marc_record, holdings_marc_records, mapping_ruleset)
          # TODO: In Hyacinth 3, support multiple project associations
          raise 'This record already has a project.' if digital_object_data['project']

          project_string_key = nil
          marc_record.fields('965').each do |field|
            project_string_key = MAP_965_TO_PROJECT[field['a']]
            break unless project_string_key.nil?
          end
          return if project_string_key.nil?
          digital_object_data['project'] = {
            'string_key' => project_string_key
          }
        end
      end
    end
  end
end
