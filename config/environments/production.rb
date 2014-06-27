# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# See everything in the log (default is :info)
# config.log_level = :debug

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Enable threaded mode
# config.threadsafe!

#config.gem 'rack-google-analytics', :lib => 'rack/google-analytics'
#config.middleware.use Rack::GoogleAnalytics, :tracker => 'UA-39742012-1'

#config.gem "inherited_resources", :version => "1.0.2"
#config.gem "responders", :version => "0.4.2"

#GA.tracker = "UA-39742012-1"

config.action_mailer.raise_delivery_errors = false

ActionMailer::Base.smtp_settings = {
  :address => "apps.otogomobile.net",
  :port => 25,
  :domain => "otogomobile.net",
  :authentication => :login,
  :user_name => "noreply",
  :password => "mtribe98754",
}

ActionController::Base.session_options[:domain] = '.otogomobile.net'
config.action_controller.session = {:domain      => '.otogomobile.net'}
