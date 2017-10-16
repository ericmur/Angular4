class Api::Web::V1::ChatsManager
  def initialize(current_advisor, chatables, options = {})
    chatables.map! { |c|
      if c.class == Client
        if c.consumer
          c.consumer
        else
          raise "Client does not have consumer_id. Chat is not supported for unconnected clients"
        end
      else
        c
      end
    }
    @workflow_id  = options[:workflow_id]
    @chat_members = chatables << current_advisor
  end

  def find_or_create_with_users
    cond = Chat.where(:id => ChatsUsersRelation.for_chatable(@chat_members.first).pluck(:chat_id))
    @chat_members[1..-1].each do |c|
      cond = Chat.where(:id => cond.pluck(:id)).where(:id => ChatsUsersRelation.for_chatable(c).pluck(:chat_id))
    end

    chat = cond.order(created_at: :desc).where(workflow_id: nil).first unless @workflow_id

    unless chat
      chat = build_chat_with_users
      chat.workflow_id = @workflow_id if @workflow_id
      chat.save
    end

    chat
  end

  def build_chat_with_users
    chat = Chat.new
    if @chat_members.count == 2 and @chat_members.find { |u| u.docyt_support? }
      chat.is_support_chat = true
    end

    @chat_members.each do |chat_member|
      chat.chats_users_relations.build(:chatable => chat_member)
    end
    chat
  end

end
