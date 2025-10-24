namespace :hysync do
  namespace :sync do
    task :email_test => :environment do
      ApplicationMailer.with(
        to: HYSYNC[:marc_sync_email_addresses],
        subject: 'Hysync Test Marc Sync Error Email',
        errors: ['Test error 1', 'Test error 2']
      ).marc_sync_error_email.deliver
    end

    # task :marc_sync => :environment do
    #   force_update = (ENV['force_update'] == 'true')
    #   dry_run = (ENV['dry_run'] == 'true')
    #   runner = Hysync::MarcSynchronizer::Runner.new(
    #     Hyacinth::Client.instance,
    #     Hysync::FolioApiClient.instance
    #   )

    #   success, errors = runner.run(force_update, dry_run)
    #   if !success
    #     ApplicationMailer.with(
    #       to: HYSYNC[:marc_sync_email_addresses],
    #       subject: "Hysync: MARC-to-Hyacinth Sync Errors (#{Date.today})",
    #       errors: errors
    #     ).marc_sync_error_email.deliver
    #   end
    # end

    task :by_bib_ids => :environment do
      runner = Hysync::MarcSynchronizer::Runner.new(
        Hyacinth::Client.instance,
        Hysync::FolioApiClient.instance
      )
      force_update = (ENV['force_update'] == 'true')
      dry_run = (ENV['dry_run'] == 'true')

      (ENV['bib_ids'] || '').split(',').each do |bib_id|
        marc_record = Hysync::FolioApiClient.instance.find_by_bib_id(bib_id)
        base_digital_object_data = Hysync::MarcSynchronizer::Runner.default_digital_object_data
        success, errors = runner.create_or_update_hyacinth_record(marc_record, base_digital_object_data, force_update, dry_run)
        if success
          puts "(#{bib_id}) Success!"
        else
          raise "Error for record #{bib_id}: " + errors.inspect
        end
      end
    end

    task :all => :environment do
      runner = Hysync::MarcSynchronizer::Runner.new(
        Hyacinth::Client.instance,
        Hysync::FolioApiClient.instance
      )
      force_update = (ENV['force_update'] == 'true')
      dry_run = (ENV['dry_run'] == 'true')
      verbose = (ENV['verbose'] == 'true')
      with_965_value = ENV.fetch('with_965_value', '965hyacinth')
      if with_965_value.blank?
        puts "Error: Invalid value for with_965_value parameter"
        next
      end

      modified_since_hours_ago = ENV['modified_since_hours_ago'].present? ? ENV['modified_since_hours_ago'] : nil
      if modified_since_hours_ago && modified_since_hours_ago !~ /^\d+$/
        puts "Error: modified_since_hours_ago parameter must be a number"
        next
      end
      modified_since = modified_since_hours_ago ? (Time.current - modified_since_hours_ago.to_i.hours).strftime('%Y-%m-%dT%H:%M:%SZ') : nil

      if verbose
        puts "Syncing #{with_965_value} records #{modified_since ? "that were modified since #{modified_since}" : '' } ...\n\n"
      end
      if modified_since

      else
        puts "Syncing ALL 965hyacinth records..."
      end

      success, errors = runner.run(
        force_update: force_update,
        dry_run: dry_run,
        modified_since: modified_since,
        with_965_value: with_965_value,
        verbose: verbose
      )

      puts ''
      if success
        puts "Success!"
      else
        puts "Errors!"
        puts errors.inspect

        ApplicationMailer.with(
          to: HYSYNC[:marc_sync_email_addresses],
          subject: "Hysync: MARC-to-Hyacinth Sync Errors (#{Date.today})",
          errors: errors
        ).marc_sync_error_email.deliver
      end

      # counter = 0
      # Hysync::FolioApiClient.instance.find_source_marc_records(modified_since: modified_since, with_965_value: with_965_value) do |marc_record_hash|
      #   puts marc_record_hash.inspect
      #   counter += 1
      #   marc_record = MARC::Record.new_from_hash(marc_record_hash)
      #   base_digital_object_data = Hysync::MarcSynchronizer::Runner.default_digital_object_data
      #   success, errors = runner.create_or_update_hyacinth_record(marc_record, base_digital_object_data, force_update, dry_run)

      #   if success
      #     puts "#{counter}: Success"
      #   else
      #     puts "#{counter}: Errors: " + errors.inspect
      #   end
      # end
    end

    # task :test_marc_parsing => :environment do
    #   unless ENV['bib_id']
    #     puts 'Error: missing required ENV variable bib_id'
    #     next
    #   end
    #   runner = Hysync::MarcSynchronizer::Runner.new(
    #     Hyacinth::Client.instance,
    #     Hysync::FolioApiClient.instance
    #   )
    #   voyager = runner.instance_variable_get(:@voyager_client)
    #   marc_record = voyager.find_by_bib_id(ENV['bib_id'])
    #   puts marc_record.inspect
    # end

    # task :check_oci8_encoding => :environment do
    #   puts "OCI8 encoding is: #{OCI8.encoding.inspect}"
    # end
  end
end
