# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

# Load rails environment
require File.expand_path('../config/environment', __dir__)

# Set environment to current environment.
set :environment, Rails.env

# Log cron output to app log directory
set :output, Rails.root.join("log/#{Rails.env}_cron_log.log")

# Override default rake task job type
job_type :rake, "cd :path && :environment_variable=:environment bundle exec rake :task --silent :output"

if Rails.env == 'hysync_prod'
  every 1.day, at: '2:00 am' do
    rake "hysync:marc_sync"
  end
end
