module Rails
  def self.settings
    @settings ||= Rails.application.config_for(:settings)
  end
end
