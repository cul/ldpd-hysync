module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module RelatedItem
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_related_item
        end

        def add_related_item(marc_record, holdings_marc_records, mapping_ruleset)
          dynamic_field_data['related_item'] ||= []

          extract_related_items(marc_record, mapping_ruleset).each do |related_item|
            dynamic_field_data['related_item'] << related_item
          end
        end

        private

          def extract_related_items(marc_record, mapping_ruleset)
            related_items = extract_preceding_title(marc_record, mapping_ruleset) +
            extract_succeeding_title(marc_record, mapping_ruleset) +
            extract_related_constituent_title(marc_record, mapping_ruleset)

            related_items += extract_is_identical_to(marc_record, mapping_ruleset) if mapping_ruleset == 'ldeotechnical'
            related_items
          end

          def extract_preceding_title(marc_record, mapping_ruleset)
            MarcSelector.all(marc_record, 780).reject { |field| field['a'].blank? && field['t'].blank? }.map do |field|
              {
                'related_item_title' => field['a'],
                'related_item_name' => {
                  'value' => field['t']
                },
                'related_item_type' => {
                  'value' => 'preceding',
                  'authority' => 'mods'
                }
              }
            end
          end

          def extract_succeeding_title(marc_record, mapping_ruleset)
            MarcSelector.all(marc_record, 785).reject { |field| field['a'].blank? && field['t'].blank? }.map do |field|
              {
                'related_item_title' => field['a'],
                'related_item_name' => {
                  'value' => field['t']
                },
                'related_item_type' => {
                  'value' => 'preceding',
                  'authority' => 'mods'
                }
              }
            end
          end

          def extract_related_constituent_title(marc_record, mapping_ruleset)
            values = []

            MarcSelector.all(marc_record, 740, indicator1: 0, indicator2: 2, a: true).each do |field|
              values << {
                'related_item_title' => MarcSelector.concat_subfield_values(field, ['a', 'n', 'p']),
                'related_item_type' => { 'value' => 'constituent', 'authority' => 'mods' }
              }
            end

            MarcSelector.all(marc_record, 730, indicator1: 0, indicator2: 2, a: true).each do |field|
              values << {
                'related_item_title' => MarcSelector.concat_subfield_values(field, ['a', 'm', 'n', 'p', 'r', 's', 'k', 'l', 'o', 'f']),
                'related_item_type' => { 'value' => 'constituent', 'authority' => 'mods' }
              }
            end

            MarcSelector.all(marc_record, 700, indicator2: 2, a: true).each do |field|
              values << {
                'related_item_name' => {
                  'value' => MarcSelector.concat_subfield_values(field, ['a', 'c', 'q', 'd'])
                },
                'related_item_title' => MarcSelector.concat_subfield_values(field, ['t', 'm', 'n', 'p', 'r', 's', 'l', 'o', 'f']),
                'related_item_type' => { 'value' => 'constituent', 'authority' => 'mods' }
              }
            end

            values
          end

          def extract_is_identical_to(marc_record, mapping_ruleset)
            title_245_ab = MarcSelector.concat_subfield_values(MarcSelector.first(marc_record, 245, a: true), ['a', 'b'])

            MarcSelector.all(marc_record, 920, indicator1: 4, indicator2: 0, u: true).map do |field|
              {
                'related_item_title' => title_245_ab,
                'related_item_type' => {
                  'value' => 'isIdenticalTo',
                  'authority' => 'datacite'
                },
                'related_item_identifier' => [
                  {
                    'related_item_identifier_type' => 'url',
                    'related_item_identifier_value' => field['u']
                  }
                ]
              }
            end
          end
      end
    end
  end
end
