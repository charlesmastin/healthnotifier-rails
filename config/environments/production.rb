HealthNotifierModule::Application.configure do
  config.eager_load = true
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.public_file_server.enabled = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

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

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  
  config.assets.precompile = ["manifest.js"]

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  #config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  config.middleware.delete Rack::Lint

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

  config.action_mailer.default_url_options = {
    :host => ENV['PORTAL_HOSTNAME'] || 'app.domain.com'
  }

  config.action_mailer.asset_host = 'https://app.domain.com'

  config.default_print_admin_email = "admin@domain.com"

  # config.active_job.default_url_options = { host: "https://api.domain.com" }

  config.after_initialize do
    Rails.application.routes.default_url_options[:host] = ENV['PORTAL_HOSTNAME'] || 'app.domain.com'
  end

end
