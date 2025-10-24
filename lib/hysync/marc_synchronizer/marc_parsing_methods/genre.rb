module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Genre
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_genre
        end

        def add_genre(marc_record, location_codes_from_holdings, mapping_ruleset)
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
          when 'carnegie_scrapbooks_and_ledgers', 'ldeotechnical', 'video'
            MarcSelector.all(marc_record, '655', indicator2: 7, a: true).each do |field|
              next if mapping_ruleset == 'ldeotechnical' && field['2'] == 'fast'

              genre_terms << {
                'value' => StringCleaner.trailing_punctuation_and_whitespace(field['a']),
                'authority' => field['2'],
                'uri' => StringCleaner.trailing_punctuation_and_whitespace(field['0'])
              }.tap do |term|
                if field['2'] == 'fast' && field['0'].present?
                  # convert FAST identifier format "(OCoLC)fst01941336" to url format "http://id.worldcat.org/fast/1941336"
                  term['uri'] = 'http://id.worldcat.org/fast/' + field['0'].gsub(/\(.+\)fst/, '')
                end
              end
            end
          else
            genre_data_for_655 = {}
            MarcSelector.all(marc_record, '655', a: true).each do |field|
              # For now, ignore FAST terms in the default mapping (because they duplicate non-FAST terms)
              next if field['2'] == 'fast'

              genre_data_for_655[field['a']] = {
                'authority' => field['2'],
                'uri' => field['0']
              }
            end

            non_655_genre_values = []
            ['600', '610', '611', '630', '647', '648', '650', '651'].each do |field_number|
              MarcSelector.all(marc_record, field_number, v: true).each do |field|
                non_655_genre_values << field['v'] unless genre_data_for_655.key?(field['v'])
              end
            end

            # De-dupe non_655_genre_values
            non_655_genre_values.uniq!

            genre_data_for_655.each do |value, data|
              genre_terms << {
                'value' => StringCleaner.trailing_punctuation_and_whitespace(value),
                'authority' => data['authority'],
                'uri' => data['uri']
              }
            end

            non_655_genre_values.each do |genre_value|
              genre_terms << {
                'value' => StringCleaner.trailing_punctuation_and_whitespace(genre_value),
                # Do not supply authority value if mapping_ruleset == annual_reports
                'authority' => (mapping_ruleset == 'annual_reports' ? '' : 'lcsh') # All 6XX fields have authority 'lcsh' (other than 655)
              }
            end
          end

          genre_terms
        end
      end
    end
  end
end
