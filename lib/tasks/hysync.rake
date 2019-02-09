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
end
