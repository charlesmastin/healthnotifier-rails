source 'http://rubygems.org'

# core
gem 'rack', '2.0.1'
gem 'rack-test', '0.6.3' #????
gem 'rack-cache', '1.2', :require => 'rack/cache'
gem 'unicorn', '5.0.1'
gem 'rails', '5.0.6'
gem 'rake', '10.4.2'
gem 'railties', '5.0.6'
gem 'polyglot', '0.3.5'
gem 'nokogiri', '1.6.7.2'
gem 'eventmachine', '1.0.4'
gem 'syck'
gem 'json', '1.8.3'
gem 'multi_json', '1.11.2'
gem 'i18n', '0.7.0'
gem 'turbolinks'
gem 'jwt'

# database / model stuffs
#group :postgresql do
#  gem 'pg', '0.17.1'
#end

gem 'pg', '0.18.4'

gem 'composite_primary_keys', '9.0.6'
gem 'seed-fu', '2.3.6'
gem 'pg_sequencer', '0.0.2'
gem 'devise', '4.3.0'
gem 'devise_uid'
# gem 'simple_token_authentication', '1.15.1'
gem 'strong-parameters'
# gem 'protected_attributes', '1.1.3'
gem 'american_date', '1.1.0'
gem 'validates_timeliness', '3.0.14'
gem 'validates_email_format_of', '1.6.2'
gem 'will_paginate', '~> 3.1.0'
gem 'ransack'
gem 'geocoder', '1.3.4'
gem 'acts_as_list', '0.7.7'
gem 'redcarpet'
# gem 'delayed_job_active_record'
# gem 'daemons'
gem 'sidekiq'

# assets
# gem 'excon', '0.45.0'
gem 'bourbon', '3.1.8'
gem 'sprockets', github: 'rails/sprockets', tag: 'v4.0.0.beta4'
gem 'sprockets-rails', :require => 'sprockets/railtie'
gem 'sass', '3.4.23'
gem 'sass-rails', '5.0.6'
gem 'jquery-rails', '4.2.2' # UGGGGGG GET RID OF THIS SO FAST AND FRESH
gem 'rmagick'#, '2.13.4', require: false
gem 'exifr', '1.2.4'
# gem 'arbre', '1.0.2'

# OMG not sure even at all though
# gem 'rb-fsevent', '0.10.2'

group :assets do
  # gem 'coffee-rails', '4.0.1'
  gem 'uglifier', '2.5.0'
end

# third party integrations
gem 'aws-sdk', '2.3.14'
gem 'airbrake', '4.0.0'
gem 'stripe', '1.43.0'
gem 'twilio-ruby'

# environment specific stuffs
group :production do
  gem 'therubyracer', '0.12.1'
  gem 'execjs', '2.0.2'
end

group :development do
  # gem 'debugger', '1.6.8'
  gem 'shog'
  gem 'guard-livereload', '~> 2.5.2', require: false
  gem 'rack-livereload'
  gem 'redis'
  gem 'byebug'
  gem 'thin', '1.6.2'
  gem 'yaml_db', '0.2.3'
  gem 'keen'
end

group :development, :test do
  gem 'rspec-rails', '3.5.2'
  gem 'rspec-its', '1.2.0'
  gem 'airborne', '0.2.8'
end

group :profile do
  gem 'ruby-prof', '0.15.1'
end
