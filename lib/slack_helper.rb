class SlackHelper
  def self.notify(channel, message, username, attachments=[])
    notifier = Slack::Notifier.new SLACK_WEBHOOK_URL, channel: channel, username: username

    notifier.ping message,
        attachments: attachments, 
        icon_emoji: ":cop:", 
        channel: channel,
        username: username
  end

  def self.ping(opts={})
    return if Rails.env.development? || Rails.env.test?
    notifier = Slack::Notifier.new SLACK_WEBHOOK_URL, channel: opts[:channel], username: opts[:username]
    message = opts[:message]
    notifier.ping "(#{Rails.env}) #{message}"
  end

  def self.with_notifier(channel, message, username, &block)
    notifier = Slack::Notifier.new SLACK_WEBHOOK_URL, channel: channel, username: username
    notifier.ping "#{Time.zone.now.to_s} : #{message} Started...", icon_emoji: ":cop:", channel: channel, username: username
    yield
    notifier.ping "#{Time.zone.now.to_s} : #{message} Completed...", icon_emoji: ":cop:", channel: channel, username: username
  end
end