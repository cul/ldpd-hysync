module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Collection
        CACHE = {}

        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_collection
        end

        def add_collection(marc_record, location_codes_from_holdings, mapping_ruleset, folio_client = nil)
          if mapping_ruleset == "annual_reports"
            dynamic_field_data['collection'] = [{
              'collection_term' => {
                'value' => 'Carnegie Corporation of New York Records',
                'uri' => 'http://id.library.columbia.edu/term/72fcfd07-f7db-4a18-bdb2-beb0abce071c'
              }
            }]
          end

          # Check for collection in 773 $w
          extract_773w_collection_term(marc_record, folio_client) if dynamic_field_data['collection'].blank?

          # Fall back to 710
          extract_710_fallback_collection(marc_record) if dynamic_field_data['collection'].blank?

          add_archival_series_to_first_collection_if_present(marc_record, mapping_ruleset)
        end

        def extract_710_fallback_collection(marc_record)
          field = MarcSelector.first(marc_record, 710, indicator1: 2, a: true, '5': 'NNC')
          return if field.blank?
          dynamic_field_data['collection'] ||= []
          dynamic_field_data['collection'] << {
            'collection_term' => {
              'value' => StringCleaner.trailing_punctuation_and_whitespace(field['a'])
            }
          }
        end

        def collection_terms
          dynamic_field_data['collection']
        end

        def extract_773w_collection_term(marc_record, folio_client)
          term = indirect_773w_term(marc_record, folio_client)

          return unless term
          dynamic_field_data['collection'] ||= []
          dynamic_field_data['collection'] << term
        end

        def indirect_773w_term(marc_record, folio_client)
          field = MarcSelector.all(marc_record, 773, w: true).find do |f|
            # Some examples of values that we're interested in
            # (NNC)1234567
            # (NNC)12345678
            # (NNC)in100200300
            # 1234567
            # 12345678
            # in100200300
            f['w'] =~ /^(\(NNC\))*(in)*\d+$/
          end

          return nil if field.nil?

          collection_folio_hrid = field['w'].sub(/^\(NNC\)/, '').sub(/^in/, '')

          # # Check cache for this value and return if found
          # return Collection::CACHE[collection_folio_hrid] if Collection::CACHE.key?(collection_folio_hrid)

          # collection_marc_record = folio_client.find_by_bib_id(collection_folio_hrid)
          # if collection_marc_record.nil?
          #   self.errors << "Could not resolve 773 $w collection value of #{field['w']} to a FOLIO record"
          #   # Cache nil to prevent thrashing to find the unfindable id
          #   Collection::CACHE[collection_folio_hrid] = nil
          #   return
          # end

          # Collection::CACHE[collection_folio_hrid] = {
          #   'collection_term' => {
          #     'clio_id' => collection_marc_record['001'].value
          #   }
          # }

          # Collection::CACHE[collection_folio_hrid]

          {
            'collection_term' => {
              'clio_id' => collection_folio_hrid
            }
          }
        end

        def add_archival_series_to_first_collection_if_present(marc_record, mapping_ruleset)
          # For now, we're only retrieving the archival series from MARC for
          # carnegie_scrapbooks_and_ledgers and gumbymicrofilm. For other mapping types, that data
          # will be entered directly into Hyacinth.
          return unless ['carnegie_scrapbooks_and_ledgers', 'gumbymicrofilm'].include?(mapping_ruleset)

          if dynamic_field_data['collection'].length > 0
            field = MarcSelector.first(marc_record, 773, indicator1: 0, g: true)
            return unless field
            dynamic_field_data['collection'].first['collection_archival_series'] = [
              {
                'collection_archival_series_part' => [
                  {
                    'collection_archival_series_part_title' => field['g'],
                    'collection_archival_series_part_type' => 'series'
                  }
                ]
              }
            ]
          end
        end
      end
    end
  end
end
