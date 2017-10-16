class PushDevice < ActiveRecord::Base
  NOTIFICATION_SOUND_FILE = "Wood_Done.wav"

  validates :device_uuid, presence: true, uniqueness: true
  validates :device_token, presence: true, uniqueness: true

  belongs_to :user

  def push(message, data={})
    n = Rpush::Apns::Notification.new
    n.app = Rpush::Apns::App.find_by_name("docyt-#{Rails.env}")
    n.device_token = self.device_token
    n.alert = message
    n.data = data
    n.badge = self.user.app_badge_counter
    n.sound = NOTIFICATION_SOUND_FILE
    n.save!

    Rpush.push
  end

end
