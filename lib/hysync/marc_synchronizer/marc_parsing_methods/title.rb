module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Title
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_title
        end

        def add_title(marc_record, mapping_ruleset)
          non_sort_portion_lenth = marc_record['245'].indicator2.nil? ? 0 : marc_record['245'].indicator2.to_i
          title = extract_title(marc_record, mapping_ruleset)
          return if title.nil?

          dynamic_field_data['title'] ||= []
          dynamic_field_data['title'] << {
            'title_non_sort_portion' => title[0...non_sort_portion_lenth],
            'title_sort_portion' => title[non_sort_portion_lenth..-1]
          }
        end

        def extract_title(marc_record, mapping_ruleset)
          field = MarcSelector.first(marc_record, 245, a: true)
          return nil if field.nil?

          title = field['a']
          case mapping_ruleset
          when 'carnegie_scrapbooks_and_ledgers', 'oral_history'
            title += ', ' + field['f'] if field['f']
          else
            title += ', ' + field['b'] if field['b']
            title += ', ' + field['f'] if field['f']
            title += ', ' + field['n'] if field['n']
            title += ', ' + field['p'] if field['p']
          end

          # remove trailing period or comma if present
          title.sub(/[.,]$/, '')
        end
      end
    end
  end
end
