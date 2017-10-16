class DownloadExhaustedNotifierJob < ActiveJob::Base
  queue_as :default

  def perform(object_id, object_klass_name)
    klass = object_klass_name.constantize
    object = klass.find_by_id(object_id)

    if object
      notifier = Slack::Notifier.new SLACK_WEBHOOK_URL, channel: '#errors', username: 'iOS-PageDownloader'
      attachment = {
        fallback: "(#{Rails.env}) #{object_klass_name} with id: ##{object.id} download exhausted after 5 retries.",
        text: "(#{Rails.env}) #{object_klass_name} with id: ##{object.id} download exhausted after 5 retries.",
        color: "warning",
        author_name: "Docyt #{Rails.env}",
        title: "#{object_klass_name}##{object_id}",
        fields: [
          {
            title: "#{object_klass_name} ID",
            value: object.id,
            short: true
          },
          {
            title: "Storage Size",
            value: object.storage_size,
            short: true
          }
        ]
      }

      notifier.ping "(#{Rails.env}) #{object_klass_name} download exhausted.", 
        attachments: [attachment], 
        icon_emoji: ":cop:", 
        channel: '#errors',
        username: 'iOS-PageDownloader'

    end
  end
end
