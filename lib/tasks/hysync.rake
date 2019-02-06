namespace :hysync do
  task :marc_sync => :environment do
    success, errors = Hysync::MarcSynchronizer::Runner.new(HYACINTH_CONFIG, VOYAGER_CONFIG).run(ENV['force_update'] == 'true')
  end

  task :email_test => :environment do
    puts 'Mail to: ' + Rails.application.credentials[:error_email_recipient].inspect
    ApplicationMailer.with(
      to: Rails.application.credentials[:error_email_recipient],
      subject: 'Test email',
      errors: ['error 1', 'error 2']
    ).marc_sync_error_email.deliver
  end
end
