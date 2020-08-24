module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module SubjectTitle
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_subject_title
        end

        def add_subject_title(marc_record, holdings_marc_records, mapping_ruleset)
          return if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'

          dynamic_field_data['subject_title'] ||= []
          extract_subject_title_terms(marc_record, mapping_ruleset).each do |subject_title_term|
            dynamic_field_data['subject_title'] << {
              'subject_title_term' => subject_title_term
            }
          end
        end

        def extract_subject_title_terms(marc_record, mapping_ruleset)
          subject_title_terms = []
          MarcSelector.all(marc_record, 630, a: true).map do |field|
            authority = field['2']
            uri = field['0']
            if authority == 'fast' && field['0'] && (fast_uri_match = field['0'].match(/^\(OCoLC\)fst(\d+)$/))
              uri = 'http://id.worldcat.org/fast/' + fast_uri_match[1]
            end

            subject_title_terms << {
              'value' => MarcSelector.concat_subfield_values(field, ['a', 'f', 'k', 'l', 'm', 'n', 'o', 'p', 'r', 's', 'x']),
              'authority' => authority,
              'uri' => uri
            }
          end

          (
            MarcSelector.all(marc_record, 600, t: true) +
            MarcSelector.all(marc_record, 610, t: true) +
            MarcSelector.all(marc_record, 611, t: true)
          ).map do |field|
            val = field['t']
            subject_title_terms << { 'value' => StringCleaner.trailing_punctuation_and_whitespace(val) }
          end

          subject_title_terms
        end
      end
    end
  end
end
