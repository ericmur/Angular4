class DocytBotSession < ActiveRecord::Base
  has_many :docyt_bot_session_documents, :dependent => :destroy

  validates :session_token, presence: true, uniqueness: true
  def self.create_with_token!
    self.create!(:session_token => Devise.friendly_token)
  end
end
