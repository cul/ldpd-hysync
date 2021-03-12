module Hysync
  module MarcSynchronizer
    module MarcParsingMethods
      module Collection
        CACHE = {}

        extend ActiveSupport::Concern
        included do
          register_parsing_method :add_collection
        end

        def add_collection(marc_record, holdings_marc_records, mapping_ruleset, voyager_client = nil)
          if mapping_ruleset == "annual_reports"
            dynamic_field_data['collection'] = [{
              'collection_term' => {
                'value' => 'Carnegie Corporation of New York Records',
                'uri' => 'http://id.library.columbia.edu/term/72fcfd07-f7db-4a18-bdb2-beb0abce071c'
              }
            }]
            return
          end

          terms = extract_collection_clio_ids(marc_record, mapping_ruleset).map do |clio_id|
             {
              'collection_term' => {
                'clio_id' => clio_id
              }
            }
          end
          dynamic_field_data['collection'] = terms unless terms.empty?
          add_indirect_773w_term(marc_record, voyager_client)
          add_fallback_collection(marc_record, holdings_marc_records, mapping_ruleset)

          add_archival_series_to_first_collection_if_present(marc_record, mapping_ruleset)
        end

        # If this marc record has a collection clio id, extract it.
        # This collection clio id, if present, will be in 773 $w and
        # will be a 7 or 8 digit number that's optionally prefixed
        # with "(NNC)".
        def extract_collection_clio_ids(marc_record, mapping_ruleset)
          clio_ids = []
          collection_field_773 = MarcSelector.first(marc_record, 773, w: true)
          if collection_field_773
            id_match = collection_field_773['w'].match(/^(\(NNC\))*(\d{7,8})$/)
            # If 773 $w doesn't match our record, this isn't a valid CLIO id reference
            clio_ids << id_match[2] if id_match # retrieve numeric portion of ID
          end
          clio_ids
        end

        # This parsing method is only called for certain mappings,
        # and only if a collection has not already been added to
        # the record.
        def add_fallback_collection(marc_record, holdings_marc_records, mapping_ruleset)
          return unless dynamic_field_data['collection'].nil?
          dynamic_field_data['collection'] ||= []
          dynamic_field_data['collection'] << {
            'collection_term' => {
              'value' => extract_fallback_collection(marc_record, mapping_ruleset)
            }
          }
        end

        def extract_fallback_collection(marc_record, mapping_ruleset)
          field = MarcSelector.first(marc_record, 710, indicator1: 2, a: true, '5': 'NNC')
          return field['a'] unless field.nil?
        end

        def collection_terms
          dynamic_field_data['collection']
        end

        def add_indirect_773w_term(marc_record, voyager_client)
          # early exit if we found a CLIO term or we don't have a z3950 client
          return unless voyager_client && collection_terms.blank?
          term = indirect_773w_term(marc_record, voyager_client)
          return unless term
          dynamic_field_data['collection'] ||= []
          dynamic_field_data['collection'] << term
        end

        def indirect_773w_term(marc_record, voyager_client)
          collection_field_773 = MarcSelector.first(marc_record, 773, w: true)
          if collection_field_773
            # do not cache if it loks like a CLIO id
            return if collection_field_773['w'].match(/^(\(NNC\))*(\d{7,8})$/)
            # others will be of a similar form, eg '(CStRLIN)NYDA01-F181', ignore terminating punctuation
            id_match = collection_field_773['w'].match(/^(\([A-Za-z0-9]+\))([A-Za-z0-9\-]+)/)
            return unless id_match
            collection_id = id_match[1] + id_match[2]
            return Collection::CACHE[collection_id] if Collection::CACHE.key?(collection_id)
            voyager_query = [1,20, collection_id]
            voyager_client.search(*voyager_query) do |collection_record, ix, total|
              if MarcSelector.all(collection_record, '035', a: collection_id).present?
                Collection::CACHE[collection_id] = {
                  'collection_term' => {
                    'clio_id' => collection_record['001'].value
                  }
                }
              end
            end
            # here we cache nil to prevent thrashing to find the unfindable id
            Collection::CACHE[collection_id] ||= nil
          end
        end

        def add_archival_series_to_first_collection_if_present(marc_record, mapping_ruleset)
          return unless ['carnegie_scrapbooks_and_ledgers', 'gumby'].include?(mapping_ruleset)

          # For now, we're only retrieving the archival series from MARC for
          # carnegie_scrapbooks_and_ledgers. For other mapping types, that data
          # will be entered directly into Hyacinth.

          if dynamic_field_data['collection'].length > 0
            field = MarcSelector.first(marc_record, 773, indicator1: 0, g: true)
            return unless field
            dynamic_field_data['collection'].first['collection_archival_series'] = [
              {
                'collection_archival_series_part' => [
                  {
                    'collection_archival_series_part_title' => field['g']
                  }.tap do |part|
                    part['collection_archival_series_part_type'] = 'series' if mapping_ruleset == 'carnegie_scrapbooks_and_ledgers'
                  end
                ]
              }
            ]
          end
        end
      end
    end
  end
end
