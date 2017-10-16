class Api::Web::V1::ChatsQuery
  def initialize(current_advisor, params = {})
    @advisor = current_advisor
  end

  def get_all_chats
    Chat.includes(:chatable_users, chats_users_relations: :user)
      .where(
        chats: { is_support_chat: false, workflow_id: nil },
        chats_users_relations: { chatable_id: @advisor.id, chatable_type: @advisor.class.name.to_s }
      )
  end
end
