class Chat < ActiveRecord::Base
  SOURCE = { :web_chat => 'WebChat', :mobile_chat => 'MobileChat' }

  belongs_to :workflow
  has_many :chats_users_relations, dependent: :destroy
  has_many :chatable_users, through: :chats_users_relations, :source_type => 'User', :source => :chatable
  has_many :chatable_clients, through: :chats_users_relations, :source_type => 'Client', :source => :chatable
  has_many :chat_documents, dependent: :destroy

  has_many :messages, class_name: 'Messagable::Message', dependent: :destroy

  def set_messages_as_read(receiver)
    message_users = get_message_users(receiver)
    message_users.update_all(read_at: Time.zone.now) if message_users.any?
  end

  def get_message_users(receiver)
    Messagable::MessageUser.joins(:message).where(messages: { chat_id: self.id }, receiver: receiver, read_at: nil)
  end

  def chat_members(advisor)
    chats_users_relations.where(chatable_type: advisor.class.name.to_s).where.not(chatable_id: advisor.id).map(&:chatable)
  end
end
