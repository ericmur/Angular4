class ChatSerializer < ActiveModel::Serializer
  attributes :id, :unread_msgs_cnt_since_last_notfn_check, :unread_messages_count, :last_time_notfn_checked, :last_time_messages_read_at, :last_message

  has_many :chats_users_relations

  #This method is Deprecated from 1.1.9 in favor of last_time_notfn_checked
  def last_time_messages_read_at
    last_time_notfn_checked
  end
  
  # This attribute actually belong to `chats_users_relations`
  # Place this here to help client side to set `last_time_chats_viewed` for current_user
  def last_time_notfn_checked
    u = scope[:user]
    r = object.chats_users_relations.for_chatable(u).first
    if r
      r.last_time_messages_read_at.present? ? r.last_time_messages_read_at : Time.zone.now
    else
      # This else block was meant for safeguard. `r` was not expected to be nil
      # If unexpectedly nil, we will try to capture the actual unread message's timestamp
      first_unread = object.messages.unread_for_receiver(u).order(created_at: :asc).first
      first_unread.present? ? first_unread.created_at : Time.zone.now
    end
  end

  def unread_messages_count
    u = scope[:user]
    unread_messages = object.messages.unread_for_receiver(u)
    unread_messages.count
  end

  def unread_msgs_cnt_since_last_notfn_check
    u = scope[:user]
    created_at_column = Messagable::MessageUser.arel_table[:created_at]
    created_at_from_timestamp_query = created_at_column.gt(last_time_notfn_checked)
    unread_messages = object.messages.unread_for_receiver(u).where(created_at_from_timestamp_query)
    unread_messages.count
  end

  def last_message
    message = object.messages.order("created_at DESC").first
    if message
      MessageSerializer.new(message, { :scope => scope, :root => false })
    else
      nil
    end
  end

end
