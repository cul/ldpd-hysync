module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module SubjectGeographic
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_subject_geographic
        end

        def add_subject_geographic(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['subject_geographic'] ||= []
          extract_subject_geographic_terms(marc_record, mapping_ruleset).each do |subject_geographic_term|
            dynamic_field_data['subject_geographic'] << {
              'subject_geographic_term' => subject_geographic_term
            }
          end
        end

        def extract_subject_geographic_terms(marc_record, mapping_ruleset)
          if mapping_ruleset == 'ldeotechnical'
            MarcSelector.all(marc_record, 651, indicator2: 7, a: true).map do |field|
              {
                'value' => StringCleaner.trailing_punctuation_and_whitespace(field['a']),
                'authority' => field['2']
              }.tap do |term|
                if field['2'] == 'fast' && field['0'].present?
                  # convert identifier "(OCoLC)fst01941336" to url "http://id.worldcat.org/fast/1941336"
                  term['uri'] = 'http://id.worldcat.org/fast/' + field['0'].gsub(/\(.+\)fst/, '')
                end
              end
            end
          else
            MarcSelector.all(marc_record, 651, indicator2: 0, a: true).map do |field|
              # For now, ignore FAST terms in the default mapping (because they duplicate non-FAST terms)
              next if field['2'] == 'fast' # next will return nil, so must use compact method later

              {
                'value' => MarcSelector.concat_subfield_values(field, ['a', 'x', 'y', 'z']),
                'authority' => 'lcsh' # always when 651 has indicator2 lcsh because we're only selecting fields where indicator 2 is 0, which means authority lcsh
              }
            end.compact
          end
        end
      end
    end
  end
end
