require 'net/http'

class FayeClientBuilder
  def initialize(channel, data)
    @message = data
    @channel = channel
  end

  def publish_message
    message = { :channel => @channel, :data => @message }
    uri = URI.parse(Rails.settings["faye_host"])
    Net::HTTP.post_form(uri, :message => message.to_json)
  end
end
