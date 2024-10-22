namespace :hysync do
  task :marc_sync => :environment do
    force_update = (ENV['force_update'] == 'true')
    dry_run = (ENV['dry_run'] == 'true')
    runner = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG)

    # If use_cached_results variable is provided, allow override.  Otherwise we'll default to
    # the setting in voyager.yml for the environment.
    if ENV.key?('use_cached_results')
      voyager = runner.instance_variable_get(:@voyager_client)
      voyager.instance_variable_get(:@z3950_config)[:use_cached_results] = (ENV['use_cached_results'] == 'true')
    end

    success, errors = runner.run(force_update, dry_run)
    if !success
      ApplicationMailer.with(
        to: HYSYNC[:marc_sync_email_addresses],
        subject: "Hysync: MARC-to-Hyacinth Sync Errors (#{Date.today})",
        errors: errors
      ).marc_sync_error_email.deliver
    end
  end

  task :email_test => :environment do
    ApplicationMailer.with(
      to: HYSYNC[:marc_sync_email_addresses],
      subject: 'Hysync Test Marc Sync Error Email',
      errors: ['Test error 1', 'Test error 2']
    ).marc_sync_error_email.deliver
  end

  task :sync_records => :environment do
    runner = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG)
    force_update = (ENV['force_update'] == 'true')
    dry_run = (ENV['dry_run'] == 'true')
    voyager = runner.instance_variable_get(:@voyager_client)
    voyager.instance_variable_get(:@z3950_config)[:use_cached_results] = false

    (ENV['bib_ids'] || '').split(',').each do |bib_id|
      marc_record = voyager.find_by_bib_id(bib_id)
      digital_object_data = runner.generate_digital_object_data_for_bib_record(marc_record)
      success, errors = runner.create_or_update_hyacinth_record(digital_object_data, force_update, dry_run)
      if success
        puts "(#{bib_id}) Success!"
      else
        raise "Error for record #{bib_id}: " + errors.inspect
      end
    end
  end

  task :sync_by_965 => :environment do
    runner = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG)
    force_update = (ENV['force_update'] == 'true')
    dry_run = (ENV['dry_run'] == 'true')
    use_cached_results = (ENV['use_cached_results'] == 'true')
    voyager = runner.instance_variable_get(:@voyager_client)
    voyager.instance_variable_get(:@z3950_config)[:use_cached_results] = use_cached_results
    voyager.search_by_965_value(ENV['value965']) do |marc_record, i, num_results, unexpected_error|
      if unexpected_error.present?
        success = false
        errors = [unexpected_error]
      else
        digital_object_data = runner.generate_digital_object_data_for_bib_record(marc_record)
        success, errors = runner.create_or_update_hyacinth_record(digital_object_data, force_update, dry_run)
      end

      if success
        puts "#{i}: Success"
      else
        puts "#{i}: Errors: " + errors.inspect
      end
    end
  end

  task :csv_for_965 => :environment do
    if ENV['value965'].blank?
      puts 'Missing required argument: value965'
      next
    end
    if ENV['csv_out_path'].blank?
      puts 'Missing required argument: csv_out_path'
      next
    end
    runner = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG)
    use_cached_results = (ENV['use_cached_results'] == 'true')
    voyager = runner.instance_variable_get(:@voyager_client)
    voyager.instance_variable_get(:@z3950_config)[:use_cached_results] = use_cached_results
    puts 'Downloading and processing records...'
    # We want to display additional debug info when this task runs
    with_log_output_to_stdout_in_development_environment do
      runner.csv_for_965(ENV['value965'], ENV['csv_out_path'])
    end
  end

  def with_log_output_to_stdout_in_development_environment
    if Rails.env.development?
      original_rails_logger = Rails.logger
      Rails.logger = Logger.new(STDOUT)
    end
    yield
    if Rails.env.development?
      Rails.logger = original_rails_logger
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
