module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Url
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_url
        end

        def add_url(marc_record, location_codes_from_holdings, mapping_ruleset)
          return if mapping_ruleset == 'ldeotechnical'

          dynamic_field_data['url'] ||= []
          extract_urls(marc_record, mapping_ruleset).each do |url|
            dynamic_field_data['url'] << url
          end
        end

        def extract_urls(marc_record, mapping_ruleset)
          urls = []
          MarcSelector.all(marc_record, '856', indicator1: 4, indicator2: 0, u: true).each do |field|
            url = {
              'url_value' => field['u']
            }
            if field['3']
              url['url_display_label'] = field['3']
            elsif field['z']
              # If $3 is not present, use $z if it's present
              url['url_display_label'] = field['z']
            end
            urls << url
          end
          urls
        end
      end
    end
  end
end
