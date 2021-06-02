module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Series
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_series
        end

        def add_series(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['series'] ||= []

          extract_series_values(marc_record, mapping_ruleset).each do |series|
            dynamic_field_data['series'] << series
          end

        end

        def extract_series_values(marc_record, mapping_ruleset)
          series_values = MarcSelector.all(marc_record, 830, a: true).map do |field|
            {
              'series_title' => MarcSelector.concat_subfield_values(field, ['a', 'n', 'p']),
              'series_number' => StringCleaner.trailing_punctuation_and_whitespace(field['v']),
              'series_issn' => StringCleaner.trailing_punctuation_and_whitespace(field['x'])
            }.tap do |series|
              series['series_is_columbia'] = true if mapping_ruleset == 'ldeotechnical'
            end
          end

          return series_values if series_values.present?

          # If no series was found, return values from backup field 490
          MarcSelector.all(marc_record, 490, indicator1: 0, a: true).map do |field|
            {
              'series_title' => StringCleaner.trailing_punctuation_and_whitespace(field['a'])
            }.tap do |series|
              series['series_is_columbia'] = true if mapping_ruleset == 'ldeotechnical'
            end
          end
        end
      end
    end
  end
end
