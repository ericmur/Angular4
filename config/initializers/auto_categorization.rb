require 'uri'

module AutoCategorization
  def self.settings
    @auto_categorization_settings ||= Rails.application.config_for(:settings)["auto_categorization_get_category_url"]
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
