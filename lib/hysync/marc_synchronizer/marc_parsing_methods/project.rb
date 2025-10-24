module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Project
        HYACINTH_2_URI_TEMPLATE = 'info:hyacinth.library.columbia.edu/projects/%s'.freeze

        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_project
        end

        def add_project(marc_record, location_codes_from_holdings, mapping_ruleset)
          existing_project = digital_object_data.fetch('project',{})['string_key']

          project_string_keys = marc_record.fields('965').map do |field|
            HYSYNC[:project_mappings][field['a'].to_sym]
          end.compact

          if project_string_keys.empty?
            self.errors << "Could not resolve 965 values to a project for: #{self.clio_id}"
            return
          end
          # pop the first mapped project off to see if it's the first or actual project for the object
          first_project_string_key = project_string_keys.shift
          if existing_project.nil?
            digital_object_data['project'] = {
              'string_key' => first_project_string_key
            }
          else
            # if the existing project doesn't equal the first key, put it all in queue for other_project
            project_string_keys.unshift(first_project_string_key) unless existing_project.eql?(first_project_string_key)
          end
          project_string_keys.each do |project_string_key|
            next if existing_project.eql?(project_string_key)
            other_projects = (dynamic_field_data['other_project'] ||= [])
            other_project_term_uri = Project.hyacinth_2_project_uri(project_string_key)
            unless other_projects.detect {|v| v.dig('other_project_term', 'uri').eql?(other_project_term_uri) }
              other_projects << Project.hyacinth_2_project_term(project_string_key)
            end
          end
        end

        def self.hyacinth_2_project_uri(project_string_key)
          HYACINTH_2_URI_TEMPLATE % project_string_key
        end

        def self.hyacinth_2_project_term(project_string_key)
          { 'other_project_term' => { 'uri' => hyacinth_2_project_uri(project_string_key)} }
        end
      end
    end
  end
end
