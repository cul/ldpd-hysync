module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module ArchiveOrgIdentifier
        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_archive_org_identifier
        end

        def add_archive_org_identifier(marc_record, holdings_marc_records, mapping_ruleset)
          return if mapping_ruleset == 'ldeotechnical'

          dynamic_field_data['archive_org_identifier'] ||= []
          MarcSelector.each_with_index(marc_record, 920, indicator1: 4, indicator2: 0, u: true) do |url920, ix|
            if url920['u'].match?(/https?:\/\/(www\.)?archive\.org\/details\//)
              dynamic_field_data['archive_org_identifier'] << {
                'archive_org_identifier_value' => url920['u'].split('/')[-1]
              }
              location = MarcSelector.at(marc_record, 856, ix)
              dynamic_field_data['archive_org_identifier'][-1]['archive_org_identifier_label'] =
                location['3'] if location
            end
          end
        end
      end
    end
  end
end
