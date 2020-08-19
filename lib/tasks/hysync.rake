namespace :hysync do
  task :marc_sync => :environment do
    success, errors = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG).run(ENV['force_update'] == 'true')
    if !success
      ApplicationMailer.with(
        to: HYSYNC['marc_sync_email_addresses'],
        subject: "Hysync: MARC-to-Hyacinth Sync Errors (#{Date.today})",
        errors: errors
      ).marc_sync_error_email.deliver
    end
  end

  task :email_test => :environment do
    ApplicationMailer.with(
      to: HYSYNC['marc_sync_email_addresses'],
      subject: 'Hysync Test Marc Sync Error Email',
      errors: ['Test error 1', 'Test error 2']
    ).marc_sync_error_email.deliver
  end

  task :sync_record => :environment do
    runner = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG)
    force_update = (ENV['force_update'] == 'true')
    dry_run = (ENV['dry_run'] == 'true')
    voyager = runner.instance_variable_get(:@voyager_client)
    voyager.instance_variable_get(:@z3950_config)['use_cached_results'] = false
    marc_record = voyager.find_by_bib_id(ENV['bib_id'])
    base_digital_object_data = Hysync::MarcSynchronizer::Runner.default_digital_object_data
    runner.create_or_update_hyacinth_record(marc_record, base_digital_object_data, force_update, dry_run)
  end

  task :sync_by_965 => :environment do
    runner = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG)
    force_update = (ENV['force_update'] == 'true')
    voyager = runner.instance_variable_get(:@voyager_client)
    voyager.instance_variable_get(:@z3950_config)['use_cached_results'] = false
    voyager.search_by_965_value(ENV['value965']) do |marc_record, i, num_results|
      base_digital_object_data = Hysync::MarcSynchronizer::Runner.default_digital_object_data
      runner.create_or_update_hyacinth_record(marc_record, base_digital_object_data, force_update)
    end
  end

  task :test_marc_parsing => :environment do
    unless ENV['bib_id']
      puts 'Error: missing required ENV variable bib_id'
      next
    end
    runner = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG)
    voyager = runner.instance_variable_get(:@voyager_client)
    marc_record = voyager.find_by_bib_id(ENV['bib_id'])
    puts marc_record.inspect
  end

  task :check_oci8_encoding => :environment do
    puts "OCI8 encoding is: #{OCI8.encoding.inspect}"
  end
end
