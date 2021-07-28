module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module SubjectTopic
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_subject_topic
        end

        OFFENSIVE_VALUE_REPLACEMENTS = {
          'Aliens' => 'Noncitizens',
          'Illegal aliens' => 'Undocumented immigrants',
          'Alien detention centers' => 'Immigrant detention centers',
          'Children of illegal aliens' => 'Children of undocumented immigrants',
          'Illegal alien children' => 'Undocumented immigrant children',
          'Illegal aliens in literature' => 'Undocumented immigrants in literature',
          'Women illegal aliens' => 'Women undocumented immigrants',
          'Alien criminals' => 'Noncitizen criminals',
          'Aliens in motion pictures' => 'Noncitizens in motion pictures',
          'Church work with aliens' => 'Church work with noncitizens',
          'Aliens in literature' => 'Noncitizens in literature',
          'Aliens in art' => 'Noncitizens in art',
          'Aliens in mass media' => 'Noncitizens in mass media',
          'Alien property' => 'Foreign-owned property',
          'Alien property (Greek law)' => 'Foreign-owned property (Greek law)',
          'Aliens (Greek law)' => 'Noncitizens (Greek law)',
          'Aliens (Jewish law)' => 'Noncitizens (Jewish law)',
          'Aliens (Islamic law)' => 'Noncitizens (Islamic law)',
          'Aliens (Roman law)' => 'Noncitizens (Roman law)',
          'Alien labor certification' => 'Foreign worker certification',
          'Women alien labor' => 'Women foreign workers',
          'Officials and employees, Alien' => 'Officials and employees, Noncitizen',
          'Foreign workers'	=> 'Noncitizen labor',
          'Alien labor'	=> 'Noncitizen labor',
          'Children of foreign workers'	=> 'Children of noncitizen laborers',
          'Children of alien laborers'	=> 'Children of noncitizen laborers',
          'Foreign worker certification'	=> 'Noncitizen labor certification',
          'Alien labor certification'	=> 'Noncitizen labor certification',
          'Women foreign workers'	=> 'Women noncitizen labor',
          'Women alien labor'	=> 'Women noncitizen labor',
          "Foreign workers' families"	=> "Noncitizen laborers' families",
          "Alien laborers' families"	=> "Noncitizen laborers' families",
          'Officials and employees, Alien'	=> 'Officials and employees, Noncitizen',
        }.freeze

        def add_subject_topic(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['subject_topic'] ||= []

          topics_seen = Set.new
          extract_subject_topic_terms(marc_record, mapping_ruleset).each do |subject_topic_term|
            # Keep track of seen subject topics so we can deduplicate repeated ones
            unique_topic_key = subject_topic_term['value'] + (subject_topic_term['authority'] || '') + (subject_topic_term['uri'] || '')
            next if topics_seen.include?(unique_topic_key)
            topics_seen.add(unique_topic_key)

            # We're filtering out "illegal aliens" and other similar offensive terms
            subject_topic_term['value'] = replace_term_if_offensive(subject_topic_term['value'])
            dynamic_field_data['subject_topic'] << {
              'subject_topic_term' => subject_topic_term
            }
          end
        end

        def extract_subject_topic_terms(marc_record, mapping_ruleset)
          MarcSelector.all(marc_record, 650, a: true).map do |field|
            val = replace_term_if_offensive(field['a'])
            val += '--' + replace_term_if_offensive(field['x']) if field['x']
            val += '--' + field['y'] if field['y']
            val += '--' + field['z'] if field['z']

            authority = nil
            uri = nil
            if field.indicator2 == '0'
              authority = 'lcsh'
            elsif field.indicator2 == '7'
              authority = field['2']

              # For now, ignore FAST terms in the default mapping (because they duplicate non-FAST terms)
              next if authority == 'fast' # next will return nil, so must use compact method later

              # # If authority is 'fast', then we'll expect to see a fast
              # # identifier in $0, which we can convert to a URI.
              # if authority == 'fast' && field['0'] && (fast_uri_match = field['0'].match(/^\(OCoLC\)fst(\d+)$/))
              #   uri = 'http://id.worldcat.org/fast/' + fast_uri_match[1]
              # end
            end

            {
              'value' => StringCleaner.trailing_punctuation_and_whitespace(val),
              'authority' => authority,
            }.tap do |term|
              term['uri'] = uri if uri
            end
          end.compact
        end

        # Given a value, replaces that value with a preferred value if it matches a value in our
        # offensive term list. If no match is found, returns the original value.
        def replace_term_if_offensive(value)
          replacement = OFFENSIVE_VALUE_REPLACEMENTS[value]
          return replacement || value
        end
      end
    end
  end
end
