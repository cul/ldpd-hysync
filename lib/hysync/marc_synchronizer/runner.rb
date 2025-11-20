module Hysync
  module MarcSynchronizer
    class Runner
      def self.default_digital_object_data
        {
          'digital_object_type' => {'string_key' => 'item' },
          'dynamic_field_data' => {},
          'identifiers' => []
        }
      end

      def initialize(hyacinth_client, folio_client)
        @hyacinth_client = hyacinth_client
        @folio_client = folio_client
        @collection_clio_ids_to_uris = @hyacinth_client.generate_collection_clio_ids_to_uris_map
        @errors = []
      end

      # Runs the synchronization action.
      # @param force_update [Boolean] Update Hyacinth records regardless of existing stored modification date (005)
      # @param dry_run [Boolean] Retrieve data, but do not perform any updates
      # @param modified_since [String] Only retrieve records modified on or after this timestamp string
      # @param with_965_value [String] Only retrieve records that have a 965 $a matching this value
      # @return [Boolean] success, [Array] errors
      def run(force_update: false, dry_run: false, modified_since: nil, with_965_value: nil, verbose: false)
        @errors = [] # clear errors
        counter = 0
        Hysync::FolioApiClient.instance.find_source_marc_records(modified_since: modified_since, with_965_value: with_965_value) do |marc_record_hash, total_records|
          counter += 1
          marc_record = MARC::Record.new_from_hash(marc_record_hash)
          puts "Record #{counter} of #{total_records}: (clio id = #{marc_record['001'].value}) #{marc_record['245']}" if verbose

          unless has_965hyacinth?(marc_record)
            puts "--> Skipping record because 965hyacinth was not present (clio id = #{marc_record['001'].value})." if verbose
            next
          end

          base_digital_object_data = self.class.default_digital_object_data
          create_or_update_hyacinth_record(marc_record, base_digital_object_data, force_update, dry_run)
        end

        [@errors.blank?, @errors]
      end

      def has_965hyacinth?(marc_record)
        marc_record.fields.each_by_tag(['965']) do |field|
          return true if field['a'] == '965hyacinth'
        end
        false
      end

      # For the given marc_hyacinth_record, this method enhances any collection_term field that only contains a 'clio_id' property.
      # This method creates a new Collection controlled vocabulary term in Hyacinth if a term with the given clio_id doesn't already exist.
      def add_collection_if_collection_clio_id_present!(marc_hyacinth_record)
        marc_hyacinth_record.digital_object_data['dynamic_field_data'].fetch("collection", []).each do |collection_term|
          collection_term = collection_term['collection_term']
          collection_clio_id = collection_term['clio_id']

          next unless collection_clio_id
          unless @collection_clio_ids_to_uris.key?(collection_clio_id)
            begin
              collection_marc_record = @folio_client.find_by_bib_id(collection_clio_id)
              # Return if a collection-level marc record wasn't found for the given clio id
              unless collection_marc_record && collection_marc_record.leader[7] == 'c'
                @errors << "For bib record #{marc_hyacinth_record.clio_id}, could not resolve collection clio id #{collection_clio_id} to a collection-level marc record."
                return
              end
              # Raise error if the marc 001 field of this record doesn't actually match the value in collection_clio_id
              raise 'Mismatch between collection_clio_id and retrieved record 001 value' if collection_clio_id != collection_marc_record['001'].value

              # Create this term because it does not exist
              term = @hyacinth_client.create_controlled_term({
                'controlled_vocabulary_string_key' => 'collection',
                'type' => 'local',
                'value' => self.class.extract_collection_record_title(collection_marc_record),
                'clio_id' => collection_clio_id
              })
              # Add newly-created term to @collection_clio_ids_to_uris so it can be used for future records
              @collection_clio_ids_to_uris[collection_clio_id] = term['uri']
            rescue Encoding::InvalidByteSequenceError => e
              marc_hyacinth_record.errors << "Collection bib record issue: #{e.message}"
            end
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
      def create_or_update_hyacinth_record(marc_record, base_digital_object_data, force_update, dry_run = false)
        location_codes_from_holdings = @folio_client.holdings_for_instance_hrid(
          marc_record['001'].value
        ).map { |folio_holdings_record|
          effective_location_id = folio_holdings_record['temporaryLocationId'] || folio_holdings_record['permanentLocationId']
          @folio_client.locations.dig(effective_location_id, 'code')
        }.compact

        marc_hyacinth_record = Hysync::MarcSynchronizer::MarcHyacinthRecord.new(
          marc_record, location_codes_from_holdings, base_digital_object_data, @folio_client
        )

        add_collection_if_collection_clio_id_present!(marc_hyacinth_record)

        if marc_hyacinth_record.clio_id.nil?
          msg = 'Missing CLIO ID for marc_hyacinth_record'
          @errors << msg
          Rails.logger.error msg
          return @errors.blank?, @errors
        end

        if dry_run
          puts "- Dry run only: #{marc_hyacinth_record.clio_id} #{marc_hyacinth_record.errors.present? ? 'failed validation' : 'passed validation'}"
        end

        if marc_hyacinth_record.errors.present?
          msg = "FOLIO record #{marc_hyacinth_record.clio_id} has the following errors: \n\t#{marc_hyacinth_record.errors.join("\n\t")}"
          @errors << msg
          Rails.logger.error msg
          puts msg if dry_run
          return @errors.blank?, @errors
        end

        # Add "clio#{bib_id}" identifier (e.g. clio12345).
        marc_hyacinth_record.digital_object_data['identifiers'] << "clio#{marc_hyacinth_record.clio_id}"

        # puts "marc_hyacinth_record: "
        # puts "Collection: #{marc_hyacinth_record.digital_object_data['dynamic_field_data']['collection']}"

        return @errors.blank?, @errors if dry_run

        # Use clio identifier to determine whether Item exists
        results = find_items_by_clio_id(marc_hyacinth_record.clio_id)
        if results.length == 0
          # Item does not already exist. Create new Item.
          response = @hyacinth_client.create_new_record(marc_hyacinth_record.digital_object_data, true)
          if response.success?
            Rails.logger.debug "Created new record (clio id = #{marc_hyacinth_record.clio_id})"
          else
            msg = "Error creating new record (clio id = #{marc_hyacinth_record.clio_id}). Errors:\n\t#{response.errors.join("\n\t")}"
            @errors << msg
            Rails.logger.error msg
          end
        elsif results.length == 1
          hyc_record = results.first
          # We want to preserve any existing identifiers from the existing item.
          reconcile_identifiers!(marc_hyacinth_record, hyc_record)

          reconcile_projects!(marc_hyacinth_record, hyc_record)

          if force_update || update_indicated?(marc_record, hyc_record)
            response = @hyacinth_client.update_existing_record(hyc_record['pid'], marc_hyacinth_record.digital_object_data, true)
            if response.success?
              Rails.logger.debug "Updated existing record (clio id = #{marc_hyacinth_record.clio_id})"
            else
              msg = "Error updating existing Hyacinth record (clio id = #{marc_hyacinth_record.clio_id}). Errors:\n\t#{response.errors.join("\n\t")}"
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

        [@errors.blank?, @errors]
      end

      # If given hyacinth_record marc_005_last_modified value is equal to given marc_record 005
      # value, return false.  Otherwise return true.
      def update_indicated?(marc_record, hyacinth_record)
        marc_005_last_modified = marc_record['005'].value
        hyc_005_last_modified = hyacinth_record['dynamic_field_data'].key?('marc_005_last_modified') ?
          hyacinth_record['dynamic_field_data']['marc_005_last_modified'].first['marc_005_last_modified_value'] : nil
        hyc_005_last_modified.nil? || marc_005_last_modified != hyc_005_last_modified
      end

      # Preserve any existing identifiers from the existing item.
      def reconcile_identifiers!(marc_hyacinth_record, existing_hyacinth_record)
        marc_hyacinth_record.digital_object_data['identifiers'].push(*(existing_hyacinth_record['identifiers']))
        marc_hyacinth_record.digital_object_data['identifiers'].uniq!
      end

      # do not attempt to reassign primary project via synch
      def reconcile_projects!(marc_hyacinth_record, existing_hyacinth_record)
        marc_project = marc_hyacinth_record.digital_object_data.dig('project', 'string_key')
        hyc_project = existing_hyacinth_record.dig('project', 'string_key')
        marc_other_projects = marc_hyacinth_record.dynamic_field_data.fetch('other_project', []).map { |t| t.dig('other_project_term', 'uri').split('/')[-1] }
        hyc_other_projects = existing_hyacinth_record['dynamic_field_data'].fetch('other_project', []).map { |t| t.dig('other_project_term', 'uri').split('/')[-1] }

        if !marc_project.eql?(hyc_project)
          marc_other_projects.unshift(marc_project)
          marc_hyacinth_record.digital_object_data['project'] = existing_hyacinth_record['project']
        end

        marc_hyacinth_record.dynamic_field_data['other_project'] = []
        (hyc_other_projects | marc_other_projects).each do |string_key|
          marc_hyacinth_record.dynamic_field_data['other_project'] << MarcParsingMethods::Project.hyacinth_2_project_term(string_key)
        end
      end

      def self.extract_collection_record_title(collection_marc_record)
        collection_record_title = collection_marc_record['245']['a']
        collection_record_title += ' ' + collection_marc_record['245']['n'] if collection_marc_record['245']['n']
        StringCleaner.trailing_punctuation_and_whitespace(collection_record_title)
      end
    end
  end
end
