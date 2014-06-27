require 'thread'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

CONF = YAML.load_file(File.join(File.dirname(__FILE__), 'app_config.yml'))

def property(key)
  CONF[RAILS_ENV][key.to_s]
end

def set_property(key, value)
  CONF[RAILS_ENV][key.to_s] = value
end

$KCODE = 'UTF-8'

# To help with slow servers
ActiveRecord::Base.verification_timeout = 570 

ActionMailer::Base.default_url_options[:host] = property(:host)
ActionController::Base.session_options[:key] = property(:session_key).to_s
ActionController::Base.session_options[:domain] = ".#{property(:cookies_domain)}" unless property(:cookies_domain).blank?

ExceptionNotification::Notifier.exception_recipients = %w(jhlee@mobiletribe.net rvenkat@mobiletribe.net)
ExceptionNotification::Notifier.sender_address = "noreply@otogomobile.net"
ExceptionNotification::Notifier.email_prefix = "Application error [oToGo Mobile]"
ExceptionNotification::Notifier.view_paths = ActionView::Base.process_view_paths(ExceptionNotification::Notifier.view_paths)
