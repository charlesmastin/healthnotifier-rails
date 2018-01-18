HealthNotifierModule::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are enabled and caching is turned on
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = true

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.public_file_server.enabled = true
  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
##at consider using this in production (install mod_xsendfile) to take advantage of apache cacheing in some cases (glassfish directs apache to serve a file directly, instead of glassfish/rails reading the file from disk and passing through apache)
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # forcing will be done via apache to allow non-ssl monitoring probes through
  config.force_ssl = false

  # See everything in the log (default is :info)
  config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = true

  # Enable threaded mode
  #config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to log
  config.active_support.deprecation = :log

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  config.active_record.schema_format = :sql

  # Expands the lines which load the assets
  config.assets.debug = true

  config.action_mailer.default_url_options = {
    :host => 'localhost:3000'
  }
  config.action_mailer.delivery_method = :smtp
    ### ^ ??? isn't this canceling the :test value above ??? [2014.04.23 cathames]

end
