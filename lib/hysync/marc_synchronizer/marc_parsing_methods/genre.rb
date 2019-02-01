module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Genre
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_genre
        end

        def add_genre(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['genre'] ||= []
          extract_genre_terms(marc_record, mapping_ruleset).each do |genre_term|
            dynamic_field_data['genre'] << {
              'genre_term' => genre_term
            }
          end
        end

        def extract_genre_terms(marc_record, mapping_ruleset)
          genre_terms = []

          case mapping_ruleset
          when 'oral_history'
            genre_terms <<  {
              'uri' => 'http://id.loc.gov/authorities/genreForms/gf2014026115', # Interviews
              'value' => 'Interviews'
            }
          when 'carnegie_scrapbooks_and_ledgers'
            MarcSelector.all(marc_record, '655', indicator2: 7, a: true).each do |field|
              genre_terms << {
                'value' => field['a']
              }.tap do |term|
                term['authority'] = field['2'] if field['2']
              end
            end
          else
            genre_values_to_authorities_for_655 = {}
            MarcSelector.all(marc_record, '655', a: true).each do |field|
              genre_values_to_authorities_for_655[field['a']] = field['2']
            end

            non_655_genre_values = []
            ['600', '610', '611', '630', '647', '648', '650', '651'].each do |field_number|
              MarcSelector.all(marc_record, field_number, v: true).each do |field|
                non_655_genre_values << field['v'] unless genre_values_to_authorities_for_655.key?(field['v'])
              end
            end

            # De-dupe non_655_genre_values
            non_655_genre_values.uniq!

            genre_values_to_authorities_for_655.each do |value, authority|
              genre_terms << {
                'value' => value,
                'authority' => authority
              }
            end

            non_655_genre_values.each do |genre_value|
              genre_terms << {
                'value' => genre_value,
                'authority' => 'lcsh' # All 6XX fields have authority 'lcsh' (other than 655)
              }
            end
          end
          genre_terms
        end
      end
    end
  end
end
