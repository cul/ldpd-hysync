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

          project_string_keys = marc_record.fields('965').map do |field|
            HYSYNC['project_mappings'][field['a']]
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
            other_projects = (dynamic_field_data['other_project'] ||= [])
            other_project_term_uri = "info:hyacinth.library.columbia.edu/projects/#{project_string_key}"
            unless other_projects.detect {|v| v.dig('other_project_term', 'uri').eql?(other_project_term_uri) }
              other_projects << {
                'other_project_term' => {
                  'uri' => other_project_term_uri
                }
              }
            end
          end
        end
      end
    end
  end
end
