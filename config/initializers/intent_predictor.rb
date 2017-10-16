require 'uri'

module IntentPredictor
  def self.settings
    @intent_predictor_settings ||= Rails.application.config_for(:settings)["docyt_bot_host"]
  end
  def self.uri
    URI(settings)
  end

  def self.host
    uri.host
  end

  def self.port
    uri.port
  end

  def self.path
    uri.path
  end
  
end
