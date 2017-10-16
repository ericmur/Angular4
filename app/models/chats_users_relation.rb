class ChatsUsersRelation < ActiveRecord::Base
  belongs_to :chatable, :polymorphic => true #There is no need for this to be polymorphic anymore, since this is only User model. Could very well be belongs_to :user. Maybe refactor in future
  belongs_to :chat

  belongs_to :user, -> { where(chats_users_relations: { chatable_type: User.name.to_s }) }, foreign_key: 'chatable_id'

  scope :for_chatable, lambda { |obj|
    where("(chatable_id = #{obj.id} and chatable_type = '#{obj.class.base_class.to_s}')")
  }

  validates :chat_id, :uniqueness => { :scope => [:chatable_id, :chatable_type] }

  after_create :set_last_time_messages_read_at

  def user_fullname
    chatable.parsed_fullname
  end

  private

  def set_last_time_messages_read_at
    ChatsUsersRelation.where(id: self.id).update_all(last_time_messages_read_at: Time.zone.now)
  end
end
