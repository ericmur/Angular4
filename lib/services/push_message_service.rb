class PushMessageService
  # https://github.com/rpush/rpush/blob/master/spec/unit/client/active_record/apns/notification_spec.rb#L23
  PUSH_ALERT_MESSAGE_MAX_LENGTH = 50

  def self.send_push_message(message, receiver)
    unless message.message_users.where(:receiver_id => receiver.id, :receiver_type => 'User').first.read_at.nil?
      return
    end

    PushDevice.where(user_id: receiver.id).each do |push_device|
      # For some reason, it caused parsing error errors (on iPhone side) when data with int value was added as the last key on hash
      # Please make sure data with type Int/Number is added first in response
      data = {
        id: message.id,
        sender_id: message.sender.id,
        chat_id: message.chat_id,
        sender_type: message.sender.class.to_s,
        created_at: message.created_at,
        read_at: message.message_users.first.read_at,
        text: message.text
      }

      sender_name = message.sender.first_name ? message.sender.first_name : message.sender.email
      message_text = "#{sender_name}: #{message.text}"
      
      if message.chat_document
        doc = message.chat_document.document

        if doc.standard_document_id
          base_name = doc.business_document? ? doc.businesses.first.name : doc.document_owners.first.owner_name
          name = base_name + " / " + doc.standard_document.standard_folder.name + " / " + doc.standard_document.name
        else
          name = doc.original_file_name
        end
        message_text = "#{sender_name} shared a document:\n #{name}"
      end

      truncated_message = message_text.truncate(PUSH_ALERT_MESSAGE_MAX_LENGTH)
      push_device.push(truncated_message, { type: 'Messagable::Message', data: data })
    end
  end
end
