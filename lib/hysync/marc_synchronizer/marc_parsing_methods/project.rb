module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Project
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_project
        end

        def add_project(marc_record, holdings_marc_records, mapping_ruleset)
          existing_project = digital_object_data.fetch('project',{})['string_key']

          project_string_key = nil
          marc_record.fields('965').each do |field|
            project_string_key = HYSYNC['project_mappings'][field['a']]
            break unless project_string_key.nil?
          end

          if project_string_key.nil?
            @errors << "Could not resolve 965 values to a project for: #{self.clio_id}"
            return
          end
          return if project_string_key.eql?(existing_project)
          # TODO: In Hyacinth 3, support multiple project associations
          raise 'This record already has a project.' unless existing_project.nil?
          digital_object_data['project'] = {
            'string_key' => project_string_key
          }
        end
      end
    end
  end
end
