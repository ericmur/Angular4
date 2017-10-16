namespace :consumer do
  task :recalculate_storage_counter, [:email] => :environment do |t, args|
    consumer = User.where(:email => args[:email]).first
    if consumer
      consumer.relcalculate_page_count
      consumer.recalculate_storage_size
    end
  end

  task :recalculate_storage_counter_for_all => :environment do |t, args|
    User.all.each do |consumer|
      consumer.recalculate_page_count
      consumer.recalculate_storage_size
    end
  end

  desc "Migrate custom documents"
  task :migrate_custom_documents => [:environment] do |t, args|
    individual_standard_folders_and_std_docs = StandardBaseDocument.where.not(:consumer_id => nil)
    individual_standard_folders_and_std_docs.each do |std_base_doc|
      next if std_base_doc.standard_base_document_account_types.first
      std_base_doc.standard_base_document_account_types.create!(:consumer_account_type_id => ConsumerAccountType::INDIVIDUAL, :show => true)
    end
  end

  desc "Set last time chats messages read by user"
  task set_last_time_chats_read_at: :environment do
    ChatsUsersRelation.find_each do |chat_user_relation|
      unread_message = chat_user_relation.chat.messages.unread_for_receiver(chat_user_relation.chatable).order(created_at: :asc).first
      if unread_message.present?
        chat_user_relation.last_time_messages_read_at = unread_message.created_at
      else
        chat_user_relation.last_time_messages_read_at = Time.zone.now
      end
      chat_user_relation.save!
    end
  end

  desc "Set last time notifications read by user"
  task set_last_time_notifications_read_at: :environment do
    User.find_each do |user|
      notification = user.notifications.unread.order(created_at: :asc).first
      if notification.present?
        user.last_time_notifications_read_at = notification.created_at
      else
        user.last_time_notifications_read_at = Time.zone.now
      end
      user.save!
    end
  end

  desc "Task fix missing ConsumerAccountType"
  task :fix_missing_consumer_account_type, [:consumer_account_type_id] => :environment do |t, args|
    consumer_account_type_id = args[:consumer_account_type_id]
    consumer_account_type = ConsumerAccountType.find(consumer_account_type_id)

    User.where(consumer_account_type_id: nil).find_each do |user|
      next if user.standard_category_id == StandardCategory::DOCYT_SUPPORT_ID
      user.consumer_account_type = consumer_account_type
      user.save!
      puts "UserFolderSetting generated for User:#{user.id}"
      UserFolderSetting.setup_folder_setting_for_user(user)
      DocumentCacheService.update_cache([:folder_setting], [user.id])
    end
  end

  desc "Add chat for contacts"
  task :add_chat_for_contacts => :environment do |t, args|
    User.all.each do |user|
      user.group_users_as_group_owner.each do |group_user|
        next if group_user.user_id.nil?
        Api::Web::V1::ChatsManager.new(group_user.group.owner, [group_user.user]).find_or_create_with_users
      end
    end
  end

  desc "Delete user and associated documents by email"
  task :delete_by_email, [:email] => :environment do |t, args|
    u = User.find_by_email(args[:email])
    u.chats.destroy_all
    u.client_seats.destroy_all
    u.document_ownerships.map(&:document).each { |d|
      d.document_permissions.where(:user_id => u.id).destroy_all
      d.destroy if d.document_owners.count == 1
    }
    u.document_ownerships.destroy_all
    DocumentPermission.where(:user_id => u.id).destroy_all
    Permission.where(:user_id => u.id).destroy_all
    UserDocumentCache.where(:user_id => u.id).destroy_all
    UserFolderSetting.where(:user_id => u.id).destroy_all
    UserStatistic.where(:user_id => u.id).destroy_all
    Messagable::Message.where(:sender_id => u.id).destroy_all
    u.destroy
  end
  
  desc "Delete user and associated documents"
  task :delete, [:phone] => :environment do |t, args|
    u = User.find_by_phone(args[:phone])
    u.chats.destroy_all
    u.client_seats.destroy_all
    u.document_ownerships.map(&:document).each { |d|
      d.document_permissions.where(:user_id => u.id).destroy_all
      d.destroy if d.document_owners.count == 1
    }
    u.document_ownerships.destroy_all
    DocumentPermission.where(:user_id => u.id).destroy_all
    Permission.where(:user_id => u.id).destroy_all
    UserDocumentCache.where(:user_id => u.id).destroy_all
    UserFolderSetting.where(:user_id => u.id).destroy_all
    UserStatistic.where(:user_id => u.id).destroy_all
    Messagable::Message.where(:sender_id => u.id).destroy_all
    u.destroy
  end
end
