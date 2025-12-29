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
          # Check for projects in the 965 $a 965hyacinth $p values
          project_string_keys = MarcSelector.first(
            marc_record, 965, a: '965hyacinth'
          )&.select { |subfield| subfield.code == 'p' }&.map(&:value) || []

          project_string_keys.uniq! # Remove any duplicates

          if project_string_keys.empty?
            self.errors << "Could not resolve any 965 $p values to a project for: #{self.clio_id}"
            return
          end

          # Isolate the first project and assign it as the primary project for this record
          first_project_string_key = project_string_keys.shift
          digital_object_data['project'] = {
            'string_key' => first_project_string_key
          }

          # Assign any remaining projects to the "other_project" field
          project_string_keys.each do |project_string_key|
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
