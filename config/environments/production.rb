Instatrace::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  #config.log_level = :info

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = true

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { :host => 'track.instatrace.com' }
  config.action_mailer.delivery_method = :sendmail
  #config.action_mailer.sendmail_settings = {
  #  :location  => '/usr/sbin/sendmail',
  #  :arguments => '-i'
  #}


  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true
  config.i18n.default_locale = :en

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  #config.log_level = :info
  # auto rotate log files, keep 10 of 100MB each
  config.logger = Logger.new(config.paths.log.first, 5,200*1024*1024)
  config.logger.level = Logger::INFO
  
end
