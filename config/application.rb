require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'dropbox_sdk'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Vayuum2
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.autoload_paths << "#{Rails.root}/lib/services"
    config.autoload_paths << "#{Rails.root}/lib/forms"
    config.autoload_paths << "#{Rails.root}/lib/queries"
    config.autoload_paths << "#{Rails.root}/app/serializers/concerns"

    config.active_job.queue_adapter = :resque

    config.generators do |g|
      g.orm :active_record
    end
  end
end

SLACK_WEBHOOK_URL="https://hooks.slack.com/services/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"
