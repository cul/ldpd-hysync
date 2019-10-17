module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module SubjectTopic
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_subject_topic
        end

        def add_subject_topic(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['subject_topic'] ||= []

          topics_seen = Set.new
          extract_subject_topic_terms(marc_record, mapping_ruleset).each do |subject_topic_term|
            # Keep track of seen subject topics so we can deduplicate repeated ones
            unique_topic_key = subject_topic_term['value'] + (subject_topic_term['authority'] || '') + (subject_topic_term['uri'] || '')
            next if topics_seen.include?(unique_topic_key)
            topics_seen.add(unique_topic_key)

            dynamic_field_data['subject_topic'] << {
              'subject_topic_term' => subject_topic_term
            }
          end
        end

        def extract_subject_topic_terms(marc_record, mapping_ruleset)
          MarcSelector.all(marc_record, 650, a: true).map do |field|
            val = field['a']
            val += '--' + field['x'] if field['x']
            val += '--' + field['y'] if field['y']
            val += '--' + field['z'] if field['z']

            authority = nil
            uri = nil
            if field.indicator2 == '0'
              authority = 'lcsh'
            elsif field.indicator2 == '7'
              authority = field['2']
              # If authority is 'fast', then we'll expect to see a fast
              # identifier in $0, which we can convert to a URI.
              if authority == 'fast' && field['0'] && (fast_uri_match = field['0'].match(/^\(OCoLC\)fst(\d+)$/))
                uri = 'http://id.worldcat.org/fast/' + fast_uri_match[1]
              end
            end

            {
              'value' => StringCleaner.trailing_punctuation(val),
              'authority' => authority,
            }.tap do |term|
              term['uri'] = uri if uri
            end
          end
        end
      end
    end
  end
end
