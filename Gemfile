source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Explicitly including io-wait dependency to match default version of the gem that comes with Ruby 3.0.
gem 'io-wait', '0.2.0'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.0.2'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Or use a null adapter for scenarios that really require no database
gem 'activerecord-nulldb-adapter'
# Use Puma as the app server
gem 'puma', '~> 5.2'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Need to pin nokogiri to 1.10.x for now because we can't build 1.11 on our deploy VMs (because of incompatible GLIBC version)
gem 'nokogiri', '~> 1.15.4'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# For z3950
# gem 'zoom', '0.5.0'
# gem 'alexandria-zoom', '0.6.0' # Using this gem instead of regular 'zoom' because this PR has not been merged: https://github.com/bricestacey/ruby-zoom/pull/4
gem 'alexandria-zoom', git: 'https://github.com/cul/cul-zoom.git', branch: 'yaz-config-fallback'
# gem 'alexandria-zoom', path: '../cul-zoom'
# For MARC parsing (using fork until PR is merged into main project)
gem 'marc', '1.0.4'
# gem 'marc', path: '../ruby-marc'
gem 'rainbow', '~> 3.0'
# As of Ruby 3.0, need to explicitly include rexml because it's a bundled gem instead of a default gem
gem 'rexml', '~> 3.2', '>= 3.2.4'
# For oracle connections
gem 'ruby-oci8', '~> 2.2.7'
# For HTTP Requests
gem 'rest-client', '~> 2.0'
# For cron tasks
gem 'whenever', require: false
# For retrying after raised errors
gem 'retriable', '~> 3.1'

# Ensure min versions of certain gems for security reasons only
gem 'rubyzip', '>= 2.0'

group :development, :test do
  # rubocop + CUL presets
  gem 'rubocul', '~> 4.0.3'
  # rspec for testing
  gem 'rspec', '>= 3.11'
  gem 'rspec-rails', '~> 5.1'
  gem 'factory_bot_rails', '~> 6.1.0'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.3'

  # Capistrano gems for deployment
  gem 'capistrano', '~> 3.17.0', require: false
  gem 'capistrano-cul', require: false
  gem 'capistrano-passenger', '~> 0.1', require: false
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'capistrano-rvm', '~> 0.1', require: false

  # Use net-ssh >= 4.2 to prevent warnings with Ruby 2.4
  gem 'net-ssh', '>= 4.2'
end

group :test do
  # # Adds support for Capybara system testing and selenium driver
  # gem 'capybara', '>= 2.15'
  # gem 'selenium-webdriver'
  # # Easy installation and use of chromedriver to run system tests with Chrome
  # gem 'chromedriver-helper'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
