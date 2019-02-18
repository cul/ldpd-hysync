module Hysync
  module MarcSynchronizer
    class Runner
      def initialize(hyacinth_config, voyager_config)
        @hyacinth_client = Hyacinth::Client.new(hyacinth_config)
        @voyager_client = Voyager::Client.new(voyager_config)
        @collection_clio_ids_to_uris = @hyacinth_client.generate_collection_clio_ids_to_uris_map
        @errors = []
      end

      # Runs the synchronization action.
      # @param force_update [Boolean] update records regardless of modification date (005) 
      # @return [Boolean] success, [Array] errors
      def run(force_update = false)
        @errors = [] # clear errors
        @voyager_client.search_by_965_value('965hyacinth') do |marc_record, i, num_results|
          Rails.logger.debug "#{i+1} of #{num_results}: (clio id = #{marc_record['001'].value}) #{marc_record['245']}"

          base_digital_object_data = {
            'digital_object_type' => {'string_key' => 'item' },
            'dynamic_field_data' => {}
          }

          create_or_update_hyacinth_record(marc_record, base_digital_object_data, force_update)
        end

        [@errors.blank?, @errors]
      end

      # Adds a collection term to the given base_digital_object_data if
      # collection info is available from the given marc_record.
      # @param digital_object_data [Hash] Hyacinth digital object properties
      # @param marc_record [MARC::Reader] ruby-marc record object
      def add_collection_if_collection_clio_id_present!(digital_object_data, marc_record)
        # If this marc record has a collection clio id, create or retrieve the
        # controlled term associated with that ID. This collection clio id, if present,
        # will be in 773 $w and will be a 7 or 8 digit number that's optionally prefixed
        #  with "(NNC)".  The referenced clio record must also be a collection-level record,
        # as indicated by MARC leader byte 7 having a value of'c'.
        digital_object_data['dynamic_field_data'].fetch("collection", []).each do |collection_term|
          collection_clio_id = collection_term["clio_id"]
          next unless collection_clio_id
          unless @collection_clio_ids_to_uris.key?(collection_clio_id)
            collection_marc_record = @voyager_client.find_by_bib_id(collection_clio_id)
            # Return if a marc record wasn't found for the given clio id
            return unless collection_marc_record
            # Return if this MARC record isn't a collection-level record.
            return unless collection_marc_record.leader[7] == 'c'
            # Raise error if the marc 001 field of this record doesn't actually match the value in collection_clio_id
            raise 'Mismatch between collection_clio_id and retrieved record 001 value' if collection_clio_id != collection_marc_record['001'].value
            # Create this term because it does not exist
            term = @hyacinth_client.create_controlled_term({
              'controlled_vocabulary_string_key' => 'collection',
              'type' => 'local',
              'value' => collection_marc_record['245']['a'].sub(/[.,]$/, ''), # remove trailing period or comma
              'clio_id' => collection_clio_id
            })
            # Add newly-created term to @collection_clio_ids_to_uris so it can be used for future records
            @collection_clio_ids_to_uris[collection_clio_id] = term['uri']
          end

          # Assign collection term to base digital object data hash
          collection_term['uri'] = @collection_clio_ids_to_uris[collection_clio_id]
        end
      end

      # @param clio_id [String]
      def find_items_by_clio_id(clio_id)
        @hyacinth_client.find_by_identifier(clio_id, { f: { digital_object_type_display_label_sim: ['Item'] } })
      end

      # @param marc_record [MARC::Reader] ruby-marc record object
      # @param base_digital_object_data [Hash] Hyacinth digital object properties
      # @param force_update [Boolean] update records regardless of modification date (005) 
      def create_or_update_hyacinth_record(marc_record, base_digital_object_data, force_update)
        holdings_marc_records = []
        @voyager_client.holdings_for_bib_id(marc_record['001'].value) do |holdings_marc_record, i, num_results|
          holdings_marc_records << holdings_marc_record
        end
        marc_hyacinth_record = Hysync::MarcSynchronizer::MarcHyacinthRecord.new(marc_record, holdings_marc_records, base_digital_object_data)
        add_collection_if_773_w_clio_id_present!(base_digital_object_data, marc_record)

        if marc_hyacinth_record.clio_id.nil?
          msg = 'Missing CLIO ID for marc_hyacinth_record'
          @errors << msg
          Rails.logger.error msg
          return
        end

        if marc_hyacinth_record.errors.present?
          msg = "CLIO record #{marc_hyacinth_record.clio_id} has the following errors: \n\t#{marc_hyacinth_record.errors.join("\n\t")}"
          @errors << msg
          Rails.logger.error msg
          return
        end

        # Use clio identifier to determine whether Item exists
        results = find_items_by_clio_id(marc_hyacinth_record.clio_id)
        if results.length == 0
          # Create new Item
          response = @hyacinth_client.create_new_record(marc_hyacinth_record.digital_object_data, true)
          if response.success?
            Rails.logger.debug "Created new record (clio id = #{marc_hyacinth_record.clio_id})"
          else
            msg = "Error creating new record (clio id = #{marc_hyacinth_record.clio_id}). Errors:\n\t#{response.errors.join("\n\t")}"
            @errors << msg
            Rails.logger.error msg
          end
        elsif results.length == 1
          pid = results.first['pid']
          # We want to preserve any existing identifiers, but also add
          # a 'clio' + bib_id one (e.g. clio12345), so we'll retrieve
          # this record's identifiers if it's an existing item.
          marc_hyacinth_record.digital_object_data['identifiers'] = results.first['identifiers']
          bib_id_based_identifier = 'clio' + marc_hyacinth_record.clio_id
          marc_hyacinth_record.digital_object_data['identifiers'] << bib_id_based_identifier unless marc_hyacinth_record.digital_object_data['identifiers'].include?(bib_id_based_identifier)

          if force_update
            marc_005_last_modified = nil # If we're forcing an update, always assume nil value for marc_005_last_modified.
          else
            # Get marc_005_last_modified date for the record we plan to update, to see if we need to update it.
            record = @hyacinth_client.find_by_pid(results.first['pid'])
            marc_005_last_modified = record['dynamic_field_data'].key?('marc_005_last_modified') ? record['dynamic_field_data']['marc_005_last_modified'].first['marc_005_last_modified_value'] : nil
          end

          # If current marc_005_last_modified is equal to marc record value, skip update because MARC source data has not changed.
          if marc_005_last_modified.nil? || marc_005_last_modified != marc_hyacinth_record.marc_005_last_modified
            response = @hyacinth_client.update_existing_record(pid, marc_hyacinth_record.digital_object_data, true)
            if response.success?
              Rails.logger.debug "Updated existing record (clio id = #{marc_hyacinth_record.clio_id})"
            else
              msg = "Error updating existing record (clio id = #{marc_hyacinth_record.clio_id}). Errors:\n\t#{response.errors.join("\n\t")}"
              @errors << msg
              Rails.logger.error msg
            end
          else
            Rails.logger.debug "Skipping update. Record has not changed. (clio id = #{marc_hyacinth_record.clio_id})"
          end
        else
          msg = "Skipped record due to errors (clio id = #{marc_hyacinth_record.clio_id})." +
            "Found more than one Hyacinth record with identifier #{hyacinth_record_identifier}, but only expected to find one. This needs to be corrected."
          @errors << msg
          Rails.logger.error msg
        end
      end
    end
  end
end
