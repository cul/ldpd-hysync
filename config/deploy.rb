# config valid for current version and patch releases of Capistrano
lock "~> 3.18.0"

# Until we retire all old CentOS VMs, we need to set the rvm_custom_path because rvm is installed
# in a non-standard location for our AlmaLinux VMs.  This is because our service accounts need to
# maintain two rvm installations for two different Linux OS versions.
set :rvm_custom_path, '~/.rvm-alma8'

set :remote_user, 'renserv'
set :application, 'hysync'
set :repo_name, "ldpd-#{fetch(:application)}"
set :repo_url, "git@github.com:cul/#{fetch(:repo_name)}.git"
set :deploy_name, "#{fetch(:application)}_#{fetch(:stage)}"
# used to run rake db:migrate, etc
set :rails_env, fetch(:deploy_name)

# Default deploy_to directory is /var/www/:application
set :deploy_to, "/opt/passenger/#{fetch(:deploy_name)}"

set :linked_files, fetch(:linked_files, []).push(
  'config/master.key',
  'config/database.yml',
  'config/hysync.yml',
  'config/hyacinth.yml',
  'config/voyager.yml'
)

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids')

set :passenger_restart_with_touch, true

# Default value for keep_releases is 5
set :keep_releases, 3

# Set default log level (which can be overridden by other environments)
set :log_level, :info

# RVM Setup, for selecting the correct ruby version (instead of capistrano-rvm gem)
set :rvm_ruby_version, fetch(:deploy_name)
[:rake, :gem, :bundle, :ruby].each do |command_to_prefix|
  SSHKit.config.command_map.prefix[command_to_prefix].push(
    "#{fetch(:rvm_custom_path, '~/.rvm')}/bin/rvm #{fetch(:rvm_ruby_version)} do"
  )
end

# Whenever gem
set :whenever_identifier, ->{ "#{fetch(:application)}_#{fetch(:stage)}" }

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: "log/capistrano.log", color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for local_user is ENV['USER']
# set :local_user, -> { `git config user.name`.chomp }

# Uncomment the following to require manually verifying the host key before first deploy.
# set :ssh_options, verify_host_key: :secure

namespace :deploy do
  desc "Report the environment"
  task :report do
    run_locally do
      puts "cap called with stage = \"#{fetch(:stage, 'none')}\""
      puts "cap would deploy to = \"#{fetch(:deploy_to, 'none')}\""
      puts "cap would install from #{fetch(:repo_url)}"
      puts "cap would install in Rails env #{fetch(:rails_env)}"
    end
  end

  desc "Add tag based on current version from VERSION file"
  task :auto_tag do
    current_version = "v#{IO.read('VERSION').strip}"

    ask(:tag, current_version)
    tag = fetch(:tag)

    system("git tag -a #{tag} -m 'auto-tagged' && git push origin --tags")
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      within release_path do
        with rails_env: fetch(:rails_env) do
          #execute :rake, 'resque:restart_workers'
        end
      end
    end
  end
end
