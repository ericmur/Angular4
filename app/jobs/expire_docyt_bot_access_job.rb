class ExpireDocytBotAccessJob < ActiveJob::Base
  queue_as :expire_docyt_bot_access

  def perform
    Document.where("docyt_bot_access_expires_at < ?", Time.now).each do |d|
      d.revoke_sharing(:with_user_id => nil)
    end
  end

end
