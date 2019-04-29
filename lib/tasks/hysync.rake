namespace :hysync do
  task :marc_sync => :environment do
    success, errors = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG).run(ENV['force_update'] == 'true')
    if !success
      ApplicationMailer.with(
        to: Rails.application.credentials[:error_email_recipient],
        subject: "Hysync: MARC-to-Hyacinth Sync Errors (#{Date.today})",
        errors: errors
      ).marc_sync_error_email.deliver
    end
  end

  task :email_test => :environment do
    ApplicationMailer.with(
      to: Rails.application.credentials[:error_email_recipient],
      subject: 'Hysync Test Marc Sync Error Email',
      errors: ['Test error 1', 'Test error 2']
    ).marc_sync_error_email.deliver
  end

  task :sync_record => :environment do
    runner = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG)
    force_update = (ENV['force_update'] == 'true')
    voyager = runner.instance_variable_get(:@voyager_client)
    marc_record = voyager.find_by_bib_id(ENV['bib_id'])
    base_digital_object_data = Hysync::MarcSynchronizer::Runner.default_digital_object_data
    voyager.instance_variable_get(:@z3950_config)['use_cached_results'] = false
    runner.create_or_update_hyacinth_record(marc_record, base_digital_object_data, force_update)
  end
end
