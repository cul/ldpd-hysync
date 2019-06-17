module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module TypeOfResource
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_type_of_resource
        end

        def add_type_of_resource(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['type_of_resource'] ||= []
          dynamic_field_data['type_of_resource'] << {
            'type_of_resource_value' => extract_type_of_resource(marc_record, mapping_ruleset),
            'type_of_resource_is_collection' => extract_type_of_resource_is_collection(marc_record, mapping_ruleset)
          }
        end

        def extract_type_of_resource_is_collection(marc_record, mapping_ruleset)
          marc_record.leader[7] == 'c'
        end

        def extract_type_of_resource(marc_record, mapping_ruleset)
          case marc_record.leader[6]
          when 'a', 't'
            return 'text'
          when 'e', 'f'
            return 'cartographic'
          when 'c', 'd'
            return 'notated music'
          when 'i'
            return 'sound recording - nonmusical'
          when 'j'
            return 'sound recording - musical'
          when 'k'
            return 'still image'
          when 'g'
            return 'moving image'
          when 'o'
            return 'kit'
          when 'r'
            return 'three dimensional object'
          when 'm'
            return 'software, multimedia'
          when 'p'
            return 'mixed material'
          end
          nil
        end
      end
    end
  end
end
