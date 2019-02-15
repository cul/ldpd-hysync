module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Location
        include LocationCodeMapping
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_location
        end

        def add_location(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['location'] ||= []
          extract_location_terms(holdings_marc_records, mapping_ruleset).each do |location_term|
            dynamic_field_data['location'] << {
              'location_term' => location_term
            }
          end
        end

        def extract_location_terms(holdings_marc_records, mapping_ruleset)
          location_terms = []
          case mapping_ruleset
          when 'carnegie_scrapbooks_and_ledgers'
            location_terms << {
              'value' => 'Rare Book & Manuscript Library, Columbia University',
              'authority' => 'marcorg',
              "code"=>"NNC-RB",
              'url' => 'http://id.library.columbia.edu/term/d2142d01-deaa-4a39-8dbd-72c4f148353f'
            }
          when 'oral_history'
            location_terms << {
              'value' => 'Columbia Center for Oral History, Columbia University',
              'authority' => 'marcorg',
              'code' => 'NyNyCOH',
              'url' => 'http://id.library.columbia.edu/term/cd34331d-899b-444a-85c4-211e045fc2ea'
            }
          else
            holdings_marc_records.each do |holdings_marc_record|
              MarcSelector.all(holdings_marc_record, 852, b: true).map do |field|
                location_term = clio_code_to_location_term(field['b'])
                location_terms << location_term unless location_term.nil?
              end
            end
          end
          location_terms
        end
      end
    end
  end
end
