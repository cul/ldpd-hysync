# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Load rails environment
require File.expand_path('../config/environment', __dir__)

# Set environment to current environment.
set :environment, Rails.env

# Log cron output to app log directory
set :output, Rails.root.join("log/#{Rails.env}_cron_log.log")

# Our job template wraps the cron job in a script that emails out any unhandled errors.
# This is a CUL provided script. More details can be found here:
# https://wiki.library.columbia.edu/display/USGSERVICES/Cron+Management
set :email_subject, 'Hysync Cron Error (via Whenever Gem)'
set :error_recipient, HYSYNC[:developer_email_address]
set :job_template, "/usr/local/bin/mailifrc -s 'Error - :email_subject' :error_recipient -- /bin/bash -l -c ':job'"

# Override default rake task job type
job_type :rake, "cd :path && :environment_variable=:environment bundle exec rake :task --silent :output"

if Rails.env == 'hysync_prod'
  every 1.day, at: '3:00 am' do
    rake "hysync:marc_sync"
  end
end
