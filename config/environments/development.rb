HealthNotifierModule::Application.configure do
  config.eager_load = false
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  config.assets.logger = false

  config.public_file_server.enabled = true

  config.assets.precompile = ["manifest.js"]

  config.log_level = :debug

  # require 'debugger'

  config.action_mailer.default_url_options = {
      :host => '10.0.1.12:3000'
  }

  config.action_mailer.delivery_method = :smtp

  config.action_mailer.smtp_settings = {
    # Settings for using AWS SES directly
    :enable_starttls_auto => true,
    :address => "email-smtp.us-west-2.amazonaws.com",
    :user_name => '',
    :password  => '',
    :authentication => :login,
    :port => 587,
  }

  config.action_mailer.logger = nil

  config.action_mailer.asset_host = 'http://10.0.1.12:3000'

  # config.active_job.default_url_options = { host: "http://10.0.1.12:3000" }

  # testing stripe subscription on separate dev stripe account son
  config.default_coverage_subscription = 'plan2016'

  # Raise exception on mass assignment protection for Active Record models
  # config.active_record.mass_assignment_sanitizer = :strict

  config.default_organization_id = 3 # at least on "my" seed data

  config.default_admin_email = "admin@domain.com"
  config.default_print_admin_email = "admin@domain.com"

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  config.after_initialize do
    ActiveRecord::Base.logger = nil
  end

  # config.middleware.insert_after(ActionDispatch::Static, Rack::LiveReload)

  config.after_initialize do
    Rails.application.routes.default_url_options[:host] = ENV['PORTAL_HOSTNAME'] || '10.0.1.12:3000'
  end

end

class DisableAssetsLogger
  def initialize(app)
    @app = app
    Rails.application.assets.logger = Logger.new('/dev/null')
  end

  def call(env)
    previous_level = Rails.logger.level
    Rails.logger.level = Logger::ERROR if env['PATH_INFO'].index("/assets/") == 0
    @app.call(env)
  ensure
    Rails.logger.level = previous_level
  end
end

# Rails.application.config.middleware.insert_before Rails::Rack::Logger, DisableAssetsLogger if Rails.env.development?
