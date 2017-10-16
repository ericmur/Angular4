class SendDocytbotMessageJob
  @queue = :high

  def self.perform(chat_id, text)
    docyt_support = User.where(:standard_category_id => StandardCategory::DOCYT_SUPPORT_ID).first
    #Generate an auth token for docyt support if one does not exist. Note it is possible that if we login via web app then this auth token will become stale but this is very rare to coincide. Anyway docyt support message will be best effort
    unless docyt_support.authentication_token
      docyt_support.update(authentication_token: Devise.friendly_token)
    end
    params = {
      "sender_type" => 'User',
      "sender_id" => docyt_support.id,
      "auth_token" => docyt_support.authentication_token,
      "text" => text,
      "type" => "web"
    }

    FayeClientBuilder.new("/chats/#{chat_id}", params).publish_message
  end
end
