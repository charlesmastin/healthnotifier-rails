require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  Bundler.require(*Rails.groups(:postgresql => %w(dev_postgresql production test_postgresql)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module HealthNotifierModule
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    #config.time_zone = '+00:00'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    ## setting below doesn't stop deprecation warning because of other gems
    ##    (see: http://stackoverflow.com/questions/20361428/rails-i18n-validation-deprecation-warning)
    ##config.i18n.enforce_available_locales = false
    I18n.config.enforce_available_locales = false

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_confirmation]

    # Enable the asset pipeline
    # config.quiet_assets = true

    config.assets.enabled = true
    config.assets.paths << Rails.root.join("files")

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.colorize_logging = false

    # Current version of TOC to which users must agree
    # Need to update both version and effective date at the same release
    # please keep a history of these in the comments as below
    #config.tou_version = '1.0'      # 11/1/2011
    config.tou_version = '1.1'       # 6/1/2012
    config.tou_effective_date = '20120601'.to_time.to_i

    ##at to reduce noise in production logs, consider config.filter_parameters
    #Added ActiveRecord::Base#has_secure_password (via ActiveModel::SecurePassword) to encapsulate dead-simple password usage with BCrypt encryption and salting.

    config.active_record.primary_key_prefix_type = :table_name_with_underscore
    config.active_record.pluralize_table_names = false
    config.active_record.default_timezone = :utc

    # http://stackoverflow.com/questions/6557311/no-route-matches-users-sign-out-devise-rails-3
    #config.action_view.javascript_expansions[:defaults] = %w(jquery.min jquery_ujs)

  # #

    #config.middleware.insert 0, 'Rack::Cache', {
    #  :verbose     => true,
    #  :metastore   => URI.encode("file:#{Rails.root}/tmp/dragonfly/cache/meta"),
    #  :entitystore => URI.encode("file:#{Rails.root}/tmp/dragonfly/cache/body")
    #}  unless Rails.env.production? || Rails.env.test_postgresql?

    # config.middleware.insert_after 'Rack::Cache', 'Dragonfly::Middleware', :images
    # config.middleware.insert_after 'Rack::Cache', 'Dragonfly::Middleware', :dfapp_digitized_files

#    config.middleware.use Rack::SslEnforcer, :except => ['/ops/'] unless Rails.env =~ /^dev/

    ### moved settings here identical in all environments [2014.04.23 cathames]
    config.action_mailer.default_url_options = {:protocol => 'https'}
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = false
    config.action_mailer.default :charset => "utf-8"
    config.action_mailer.smtp_settings = {
      :enable_starttls_auto => false,
      :openssl_verify_mode => 'none'
    }

    # privacy moved to fake model in Values service
    config.privacy_permission_denied_message = 'Privacy Restricted Item: ask patient'
    config.import_emrs = {} #:athenahealth => 'Athena Health' #, :bluecross => 'Blue Cross'}
    

    # stripe related stuffs, but not exactly
    config.default_coverage_cost = 2500
    config.default_replacement_sticker_cost = 500
    config.default_coverage_subscription = 'asubscriptionid'
    config.default_organization_id = 2 # this will eventually be in the db as a flag per org

    config.office_address = {
        :address1 => '50 Hawthorne. St',
        :address2 => '',
        :city => 'San Francisco',
        :postal_code => '94105',
        :state_province => 'CA'
    }

    config.default_admin_email = "admin@domain.com"

    config.to_prepare do
      Devise::Mailer.layout "email" # email.haml or email.erb
    end

    config.active_job.queue_adapter = :sidekiq

  end
end

"""
# hack monkey patch!! because xml problems:
#http://stackoverflow.com/questions/5954198/is-rails-3-1-edge-breaking-xmlmarkupbuilder
# probably don't need with ruby 1.9
if RUBY_VERSION.split('.')[0].to_i >= 1 && RUBY_VERSION.split('.')[1].to_i >= 9
  class String
    alias_method :orig_fast_xs, :fast_xs
    def fast_xs(ignore)
      orig_fast_xs
    end
  end
end
"""
