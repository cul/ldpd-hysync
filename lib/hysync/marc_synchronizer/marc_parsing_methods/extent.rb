module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Extent
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_extent
        end

        def add_extent(marc_record, mapping_ruleset)
          dynamic_field_data['extent'] ||= []
          dynamic_field_data['extent'] << {
            'extent_value' => extract_extent(marc_record, mapping_ruleset)
          }
        end

        def extract_extent(marc_record, mapping_ruleset)
          case mapping_ruleset
          when 'carnegie_scrapbooks_and_ledgers', 'oral_history'
            return
          else
            field = MarcSelector.first(marc_record, 300, a: true)
            unless field.nil?
              val = field['a']
              val += ' ' + field['b'] if field['b']
              val += ' ' + field['c'] if field['c']
              val += ' ' + field['f'] if field['f']
              return val
            end
          end
          nil
        end
      end
    end
  end
end
