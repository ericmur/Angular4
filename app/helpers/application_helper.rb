require 'useragent'

module ApplicationHelper
  def app_url_scheme(path=nil)
    settings = Rails.application.config_for(:settings)
    "#{settings["app_url_scheme"]}app#{path}"
  end

  def client_root_url(client, path)
    root_url + ['clients', client.id, path].join('/').gsub('//','/')
  end

  def from_iphone?(ua=nil)
    ua ||= request.user_agent
    user_agent = UserAgent.parse(ua)
    user_agent.platform == 'iPhone'
  end
end
