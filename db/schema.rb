# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170531160419) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "advisor_default_folders", force: :cascade do |t|
    t.integer  "standard_category_id"
    t.integer  "standard_folder_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "aliases", force: :cascade do |t|
    t.string   "name"
    t.integer  "aliasable_id"
    t.string   "aliasable_type"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  create_table "avatars", force: :cascade do |t|
    t.string   "s3_object_key"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "state"
    t.integer  "avatarable_id"
    t.string   "avatarable_type"
  end

  create_table "business_documents", force: :cascade do |t|
    t.integer  "business_id"
    t.integer  "document_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "business_documents", ["business_id"], name: "index_business_documents_on_business_id", using: :btree
  add_index "business_documents", ["document_id"], name: "index_business_documents_on_document_id", using: :btree

  create_table "business_informations", force: :cascade do |t|
    t.string   "name"
    t.string   "phone"
    t.string   "email"
    t.string   "address_street"
    t.string   "address_city"
    t.string   "address_state"
    t.string   "address_zip"
    t.integer  "standard_category_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  add_index "business_informations", ["standard_category_id"], name: "index_business_informations_on_standard_category_id", using: :btree

  create_table "business_partners", force: :cascade do |t|
    t.integer  "business_id"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "business_partners", ["business_id"], name: "index_business_partners_on_business_id", using: :btree
  add_index "business_partners", ["user_id"], name: "index_business_partners_on_user_id", using: :btree

  create_table "businesses", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "entity_type"
    t.string   "address_street"
    t.string   "address_state"
    t.string   "address_zip"
    t.string   "address_city"
    t.integer  "standard_category_id"
  end

  add_index "businesses", ["standard_category_id"], name: "index_businesses_on_standard_category_id", using: :btree

  create_table "chat_documents", force: :cascade do |t|
    t.integer  "chat_id"
    t.integer  "document_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.integer  "message_id"
  end

  add_index "chat_documents", ["chat_id"], name: "index_chat_documents_on_chat_id", using: :btree
  add_index "chat_documents", ["document_id"], name: "index_chat_documents_on_document_id", using: :btree
  add_index "chat_documents", ["message_id"], name: "index_chat_documents_on_message_id", using: :btree

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at",                      null: false
    t.datetime "updated_at",                      null: false
    t.boolean  "is_support_chat", default: false
    t.integer  "workflow_id"
  end

  create_table "chats_users_relations", force: :cascade do |t|
    t.integer  "chat_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "chatable_id"
    t.string   "chatable_type"
    t.datetime "last_time_messages_read_at"
  end

  add_index "chats_users_relations", ["chatable_type", "chatable_id"], name: "index_chats_users_relations_on_chatable_type_and_chatable_id", using: :btree

  create_table "clients", force: :cascade do |t|
    t.integer  "advisor_id"
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.string   "phone_normalized"
    t.integer  "consumer_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "structure_type"
    t.integer  "business_id"
  end

  add_index "clients", ["advisor_id", "consumer_id"], name: "index_clients_on_advisor_id_and_consumer_id", using: :btree
  add_index "clients", ["business_id"], name: "index_clients_on_business_id", using: :btree

  create_table "cloud_service_authorizations", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "cloud_service_id"
    t.string   "uid"
    t.string   "encrypted_token"
    t.string   "encrypted_token_salt"
    t.string   "encrypted_token_iv"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "cloud_service_authorizations", ["cloud_service_id"], name: "index_cloud_service_authorizations_on_cloud_service_id", using: :btree
  add_index "cloud_service_authorizations", ["user_id"], name: "index_cloud_service_authorizations_on_user_id", using: :btree

  create_table "cloud_service_paths", force: :cascade do |t|
    t.integer  "consumer_id"
    t.string   "path"
    t.string   "hash_sum"
    t.datetime "processed_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "path_display_name"
    t.integer  "cloud_service_authorization_id"
  end

  add_index "cloud_service_paths", ["cloud_service_authorization_id"], name: "index_cloud_service_paths_on_cloud_service_authorization_id", using: :btree
  add_index "cloud_service_paths", ["consumer_id"], name: "index_cloud_service_paths_on_consumer_id", using: :btree

  create_table "cloud_services", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "consumer_account_types", force: :cascade do |t|
    t.string   "display_name",              null: false
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.money    "monthly_pricing", scale: 2
    t.money    "annual_pricing",  scale: 2
  end

  add_index "consumer_account_types", ["display_name"], name: "index_consumer_account_types_on_display_name", unique: true, using: :btree

  create_table "consumer_folder_account_types", force: :cascade do |t|
    t.integer  "standard_folder_id"
    t.integer  "consumer_account_type_id"
    t.boolean  "show",                     default: true
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "consumer_folder_account_types", ["consumer_account_type_id"], name: "index_consumer_folder_account_types_on_consumer_account_type_id", using: :btree
  add_index "consumer_folder_account_types", ["standard_folder_id", "consumer_account_type_id"], name: "consumer_folder_acc_types_uni_index", unique: true, using: :btree
  add_index "consumer_folder_account_types", ["standard_folder_id"], name: "index_consumer_folder_account_types_on_standard_folder_id", using: :btree

  create_table "consumer_groups", force: :cascade do |t|
    t.integer  "consumer_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "credit_cards", force: :cascade do |t|
    t.string   "stripe_token"
    t.string   "holder_name"
    t.string   "company"
    t.string   "bill_address"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.integer  "user_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.string   "customer_token"
  end

  add_index "credit_cards", ["user_id"], name: "index_credit_cards_on_user_id", using: :btree

  create_table "default_favorites", force: :cascade do |t|
    t.integer "standard_document_id"
  end

  create_table "devices", force: :cascade do |t|
    t.string   "device_uuid"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.integer  "user_id"
    t.string   "name"
    t.text     "pass_code"
  end

  add_index "devices", ["device_uuid", "user_id"], name: "index_devices_on_device_uuid_and_user_id", unique: true, using: :btree

  create_table "dimensions", force: :cascade do |t|
    t.float    "width"
    t.float    "height"
    t.string   "unit"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "document_access_requests", force: :cascade do |t|
    t.integer  "document_id"
    t.integer  "created_by_user_id"
    t.integer  "uploader_id"
    t.datetime "created_at",         null: false
    t.datetime "updated_at",         null: false
  end

  add_index "document_access_requests", ["document_id"], name: "index_document_access_requests_on_document_id", using: :btree

  create_table "document_archives", force: :cascade do |t|
    t.integer  "suggested_standard_document_id"
    t.integer  "rejected_at"
    t.datetime "suggested_at"
    t.integer  "consumer_id"
    t.string   "source"
    t.string   "file_content_type"
    t.string   "cloud_service_full_path"
    t.string   "original_file_name"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  create_table "document_field_values", force: :cascade do |t|
    t.integer  "document_id"
    t.text     "encrypted_value"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.integer  "local_standard_document_field_id"
    t.text     "value"
    t.integer  "notification_level",               default: 0
  end

  add_index "document_field_values", ["document_id", "local_standard_document_field_id"], name: "document_field_values_index", using: :btree

  create_table "document_owners", force: :cascade do |t|
    t.integer  "document_id"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "document_owners", ["document_id", "owner_id", "owner_type"], name: "document_owners_unique_idx", unique: true, using: :btree
  add_index "document_owners", ["owner_id", "owner_type"], name: "index_document_owners_on_owner_id_and_owner_type", using: :btree

  create_table "document_permissions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "document_id"
    t.string   "value"
    t.string   "user_type"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "document_permissions", ["document_id"], name: "index_document_permissions_on_document_id", using: :btree
  add_index "document_permissions", ["user_id"], name: "index_document_permissions_on_user_id", using: :btree

  create_table "document_preparers", force: :cascade do |t|
    t.integer  "preparer_id"
    t.integer  "document_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "document_preparers", ["document_id"], name: "index_document_preparers_on_document_id", using: :btree
  add_index "document_preparers", ["preparer_id"], name: "index_document_preparers_on_preparer_id", using: :btree

  create_table "document_upload_emails", force: :cascade do |t|
    t.integer  "standard_document_id"
    t.integer  "consumer_id"
    t.string   "email"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "consumer_email"
    t.integer  "business_id"
  end

  add_index "document_upload_emails", ["consumer_id", "standard_document_id"], name: "document_upload_emails_consumer_idx", unique: true, using: :btree
  add_index "document_upload_emails", ["consumer_id"], name: "index_document_upload_emails_on_consumer_id", using: :btree
  add_index "document_upload_emails", ["email"], name: "index_document_upload_emails_on_email", using: :btree

  create_table "documents", force: :cascade do |t|
    t.integer  "consumer_id"
    t.integer  "standard_document_id"
    t.boolean  "current",                        default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source",                         default: "Photos"
    t.string   "original_file_name"
    t.string   "original_file_key"
    t.integer  "storage_size",                   default: 0
    t.string   "state"
    t.integer  "group_rank",                     default: 0
    t.integer  "cloud_service_revision"
    t.datetime "suggested_at"
    t.integer  "suggested_standard_document_id"
    t.string   "file_content_type"
    t.integer  "cloud_service_authorization_id"
    t.string   "cloud_service_last_modified_at"
    t.datetime "last_modified_at"
    t.integer  "cloud_service_path_id"
    t.string   "cloud_service_full_path"
    t.string   "final_file_key"
    t.boolean  "initial_pages_completed",        default: false
    t.integer  "email_id"
    t.string   "first_page_thumbnail"
    t.datetime "docyt_bot_access_expires_at"
  end

  add_index "documents", ["cloud_service_authorization_id"], name: "index_documents_on_cloud_service_authorization_id", using: :btree
  add_index "documents", ["cloud_service_path_id"], name: "index_documents_on_cloud_service_path_id", using: :btree
  add_index "documents", ["consumer_id", "standard_document_id"], name: "index_documents_on_consumer_id_and_standard_document_id", using: :btree
  add_index "documents", ["consumer_id", "suggested_standard_document_id"], name: "auto_categorization_index", using: :btree
  add_index "documents", ["email_id"], name: "index_documents_on_email_id", using: :btree
  add_index "documents", ["id", "consumer_id"], name: "index_documents_on_id_and_consumer_id", using: :btree

  create_table "docyt_bot_session_documents", force: :cascade do |t|
    t.integer  "docyt_bot_session_id"
    t.integer  "document_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "response_group"
  end

  create_table "docyt_bot_sessions", force: :cascade do |t|
    t.string   "session_token"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "docyt_bot_sessions", ["session_token"], name: "index_docyt_bot_sessions_on_session_token", unique: true, using: :btree

  create_table "docyt_bot_user_questions", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "phone"
    t.string   "email"
    t.text     "query_string"
    t.string   "intent"
    t.text     "document_ids"
    t.text     "field_ids"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  add_index "docyt_bot_user_questions", ["email"], name: "index_docyt_bot_user_questions_on_email", using: :btree
  add_index "docyt_bot_user_questions", ["intent"], name: "index_docyt_bot_user_questions_on_intent", using: :btree
  add_index "docyt_bot_user_questions", ["phone"], name: "index_docyt_bot_user_questions_on_phone", using: :btree
  add_index "docyt_bot_user_questions", ["user_id"], name: "index_docyt_bot_user_questions_on_user_id", using: :btree

  create_table "emails", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "from_address",         null: false
    t.text     "to_addresses",         null: false
    t.text     "subject"
    t.text     "body_text"
    t.text     "body_html"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "standard_document_id"
    t.string   "s3_bucket_name"
    t.string   "s3_object_key"
    t.integer  "business_id"
  end

  add_index "emails", ["business_id"], name: "index_emails_on_business_id", using: :btree
  add_index "emails", ["user_id"], name: "index_emails_on_user_id", using: :btree

  create_table "favorites", force: :cascade do |t|
    t.integer  "document_id"
    t.integer  "consumer_id"
    t.integer  "rank"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "favorites", ["consumer_id", "document_id"], name: "index_favorites_on_consumer_id_and_document_id", unique: true, using: :btree

  create_table "faxes", force: :cascade do |t|
    t.string   "status"
    t.string   "fax_number"
    t.integer  "sender_id"
    t.integer  "document_id"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "phaxio_id"
    t.string   "status_message"
    t.integer  "pages_count",    default: 0
  end

  add_index "faxes", ["document_id", "sender_id"], name: "index_faxes_on_document_id_and_sender_id", using: :btree

  create_table "first_time_standard_documents", force: :cascade do |t|
    t.integer  "standard_document_id"
    t.integer  "consumer_account_type_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "first_time_standard_documents", ["consumer_account_type_id", "standard_document_id"], name: "first_time_docs_index", using: :btree

  create_table "group_user_advisors", force: :cascade do |t|
    t.integer  "advisor_id"
    t.integer  "group_user_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "group_user_advisors", ["advisor_id"], name: "index_group_user_advisors_on_advisor_id", using: :btree
  add_index "group_user_advisors", ["group_user_id"], name: "index_group_user_advisors_on_group_user_id", using: :btree

  create_table "group_users", force: :cascade do |t|
    t.integer  "group_id"
    t.integer  "user_id"
    t.string   "label"
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.string   "phone_normalized"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "profile_background"
    t.datetime "unlinked_at"
    t.string   "structure_type",     default: "flat"
    t.integer  "business_id"
  end

  add_index "group_users", ["business_id"], name: "index_group_users_on_business_id", using: :btree
  add_index "group_users", ["group_id", "user_id"], name: "index_group_users_on_group_id_and_user_id", unique: true, using: :btree
  add_index "group_users", ["user_id"], name: "index_group_users_on_user_id", using: :btree

  create_table "groups", force: :cascade do |t|
    t.integer  "standard_group_id"
    t.integer  "owner_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "groups", ["owner_id", "standard_group_id"], name: "index_groups_on_owner_id_and_standard_group_id", using: :btree

  create_table "intents", force: :cascade do |t|
    t.string   "intent"
    t.text     "utterance_hash"
    t.text     "utterance_args_hash"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  create_table "invitations", force: :cascade do |t|
    t.string   "email"
    t.string   "phone"
    t.string   "phone_normalized"
    t.string   "token"
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.integer  "accepted_by_user_id"
    t.integer  "created_by_user_id"
    t.integer  "group_user_id"
    t.boolean  "email_invitation",    default: true, null: false
    t.boolean  "text_invitation",     default: true, null: false
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.string   "state"
    t.integer  "rejected_by_user_id"
    t.string   "invitee_type"
    t.string   "type"
    t.integer  "client_id"
    t.text     "text_content"
  end

  add_index "invitations", ["client_id"], name: "index_invitations_on_client_id", using: :btree
  add_index "invitations", ["email", "phone_normalized"], name: "index_invitations_on_email_and_phone_normalized", using: :btree
  add_index "invitations", ["group_user_id"], name: "index_invitations_on_group_user_id", using: :btree
  add_index "invitations", ["phone_normalized"], name: "index_invitations_on_phone_normalized", using: :btree
  add_index "invitations", ["state"], name: "index_invitations_on_state", using: :btree

  create_table "locations", force: :cascade do |t|
    t.float    "longitude"
    t.float    "latitude"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "locationable_id"
    t.string   "locationable_type"
  end

  add_index "locations", ["locationable_type", "locationable_id"], name: "index_locations_on_locationable_type_and_locationable_id", using: :btree

  create_table "message_users", force: :cascade do |t|
    t.string   "receiver_type"
    t.integer  "receiver_id"
    t.datetime "read_at"
    t.integer  "message_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "notify_at"
  end

  add_index "message_users", ["message_id"], name: "index_message_users_on_message_id", using: :btree
  add_index "message_users", ["receiver_id"], name: "index_message_users_on_receiver_id", using: :btree
  add_index "message_users", ["receiver_type"], name: "index_message_users_on_receiver_type", using: :btree

  create_table "messages", force: :cascade do |t|
    t.integer  "sender_id"
    t.integer  "chat_id"
    t.text     "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "type"
    t.datetime "edited_at"
  end

  add_index "messages", ["chat_id", "created_at"], name: "index_messages_on_chat_id_and_created_at", using: :btree
  add_index "messages", ["chat_id"], name: "index_messages_on_chat_id", using: :btree
  add_index "messages", ["sender_id"], name: "index_messages_on_sender_id", using: :btree

  create_table "notifications", force: :cascade do |t|
    t.integer  "sender_id"
    t.integer  "recipient_id"
    t.integer  "notifiable_id"
    t.string   "notifiable_type"
    t.boolean  "unread",            default: true, null: false
    t.integer  "notification_type"
    t.text     "message",                          null: false
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "notifications", ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id", using: :btree
  add_index "notifications", ["notification_type"], name: "index_notifications_on_notification_type", using: :btree
  add_index "notifications", ["recipient_id", "created_at"], name: "notifications_recipient_created_idx", using: :btree
  add_index "notifications", ["recipient_id"], name: "index_notifications_on_recipient_id", using: :btree
  add_index "notifications", ["unread"], name: "index_notifications_on_unread", using: :btree

  create_table "notify_durations", force: :cascade do |t|
    t.integer  "standard_document_field_id"
    t.float    "amount"
    t.string   "unit"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "notify_durations", ["standard_document_field_id"], name: "index_notify_durations_on_standard_document_field_id", using: :btree

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", null: false
    t.integer  "application_id",    null: false
    t.string   "token",             null: false
    t.integer  "expires_in",        null: false
    t.text     "redirect_uri",      null: false
    t.datetime "created_at",        null: false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  add_index "oauth_access_grants", ["token"], name: "index_oauth_access_grants_on_token", unique: true, using: :btree

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id"
    t.integer  "application_id"
    t.string   "token",             null: false
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        null: false
    t.string   "scopes"
  end

  add_index "oauth_access_tokens", ["refresh_token"], name: "index_oauth_access_tokens_on_refresh_token", unique: true, using: :btree
  add_index "oauth_access_tokens", ["resource_owner_id"], name: "index_oauth_access_tokens_on_resource_owner_id", using: :btree
  add_index "oauth_access_tokens", ["token"], name: "index_oauth_access_tokens_on_token", unique: true, using: :btree

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",         null: false
    t.string   "uid",          null: false
    t.string   "secret",       null: false
    t.text     "redirect_uri", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_applications", ["uid"], name: "index_oauth_applications_on_uid", unique: true, using: :btree

  create_table "pages", force: :cascade do |t|
    t.integer  "document_id"
    t.string   "s3_object_key"
    t.string   "name"
    t.integer  "page_num"
    t.string   "state"
    t.string   "original_s3_object_key"
    t.integer  "storage_size",           limit: 8, default: 0
    t.string   "source",                           default: "Camera"
    t.integer  "version",                          default: 0
    t.string   "original_file_md5"
    t.string   "final_file_md5"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pages", ["created_at"], name: "index_pages_on_created_at", using: :btree
  add_index "pages", ["s3_object_key"], name: "index_pages_on_s3_object_key", unique: true, using: :btree

  create_table "participants", force: :cascade do |t|
    t.integer  "workflow_id"
    t.integer  "user_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "participants", ["user_id"], name: "index_participants_on_user_id", using: :btree
  add_index "participants", ["workflow_id"], name: "index_participants_on_workflow_id", using: :btree

  create_table "payment_transactions", force: :cascade do |t|
    t.money    "amount",  scale: 2
    t.datetime "date"
    t.integer  "user_id"
  end

  add_index "payment_transactions", ["user_id"], name: "index_payment_transactions_on_user_id", using: :btree

  create_table "permissions", force: :cascade do |t|
    t.integer  "folder_structure_owner_id"
    t.string   "folder_structure_owner_type"
    t.integer  "user_id"
    t.string   "value"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "standard_base_document_id"
  end

  add_index "permissions", ["folder_structure_owner_id", "folder_structure_owner_type"], name: "folder_structure_owner_idx", using: :btree
  add_index "permissions", ["user_id"], name: "index_permissions_on_user_id", using: :btree
  add_index "permissions", ["value"], name: "index_permissions_on_value", using: :btree

  create_table "purchase_items", force: :cascade do |t|
    t.string   "name"
    t.string   "product_identifier"
    t.decimal  "price",              default: 0.0
    t.integer  "fax_credit_value",   default: 0
    t.boolean  "enabled",            default: true
    t.datetime "deleted_at"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.float    "discount",           default: 0.0
  end

  add_index "purchase_items", ["name"], name: "index_purchase_items_on_name", using: :btree
  add_index "purchase_items", ["product_identifier"], name: "index_purchase_items_on_product_identifier", using: :btree

  create_table "push_devices", force: :cascade do |t|
    t.string   "device_uuid"
    t.string   "device_token"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.integer  "user_id"
  end

  add_index "push_devices", ["device_uuid", "device_token"], name: "index_push_devices_on_device_uuid_and_device_token", unique: true, using: :btree
  add_index "push_devices", ["user_id"], name: "index_push_devices_on_user_id", using: :btree

  create_table "referral_codes", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "referral_codes", ["code"], name: "index_referral_codes_on_code", using: :btree
  add_index "referral_codes", ["user_id"], name: "index_referral_codes_on_user_id", using: :btree

  create_table "requests", force: :cascade do |t|
    t.integer  "workflow_id"
    t.integer  "requestionable_id"
    t.string   "requestionable_type"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "requests", ["requestionable_type", "requestionable_id"], name: "index_requests_on_requestionable_type_and_requestionable_id", using: :btree
  add_index "requests", ["workflow_id"], name: "index_requests_on_workflow_id", using: :btree

  create_table "reviews", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "last_version"
    t.boolean  "refused",      default: false
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "reviews", ["user_id"], name: "index_reviews_on_user_id", using: :btree

  create_table "rpush_apps", force: :cascade do |t|
    t.string   "name",                                null: false
    t.string   "environment"
    t.text     "certificate"
    t.string   "password"
    t.integer  "connections",             default: 1, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "type",                                null: false
    t.string   "auth_key"
    t.string   "client_id"
    t.string   "client_secret"
    t.string   "access_token"
    t.datetime "access_token_expiration"
  end

  create_table "rpush_feedback", force: :cascade do |t|
    t.string   "device_token", limit: 64, null: false
    t.datetime "failed_at",               null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "app_id"
  end

  add_index "rpush_feedback", ["device_token"], name: "index_rpush_feedback_on_device_token", using: :btree

  create_table "rpush_notifications", force: :cascade do |t|
    t.integer  "badge"
    t.string   "device_token",      limit: 64
    t.string   "sound",                        default: "default"
    t.string   "alert"
    t.text     "data"
    t.integer  "expiry",                       default: 86400
    t.boolean  "delivered",                    default: false,     null: false
    t.datetime "delivered_at"
    t.boolean  "failed",                       default: false,     null: false
    t.datetime "failed_at"
    t.integer  "error_code"
    t.text     "error_description"
    t.datetime "deliver_after"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "alert_is_json",                default: false
    t.string   "type",                                             null: false
    t.string   "collapse_key"
    t.boolean  "delay_while_idle",             default: false,     null: false
    t.text     "registration_ids"
    t.integer  "app_id",                                           null: false
    t.integer  "retries",                      default: 0
    t.string   "uri"
    t.datetime "fail_after"
    t.boolean  "processing",                   default: false,     null: false
    t.integer  "priority"
    t.text     "url_args"
    t.string   "category"
    t.boolean  "content_available",            default: false
  end

  add_index "rpush_notifications", ["delivered", "failed"], name: "index_rpush_notifications_multi", where: "((NOT delivered) AND (NOT failed))", using: :btree

  create_table "standard_base_document_owners", force: :cascade do |t|
    t.integer  "standard_base_document_id"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  add_index "standard_base_document_owners", ["owner_type", "owner_id"], name: "index_standard_base_document_owners_on_owner_type_and_owner_id", using: :btree
  add_index "standard_base_document_owners", ["standard_base_document_id", "owner_id", "owner_type"], name: "base_document_owners_index", unique: true, using: :btree

  create_table "standard_base_documents", force: :cascade do |t|
    t.string  "name"
    t.string  "type"
    t.boolean "category"
    t.integer "rank"
    t.string  "description"
    t.string  "size"
    t.string  "icon_name_1x"
    t.string  "icon_name_2x"
    t.string  "icon_name_3x"
    t.boolean "default"
    t.integer "consumer_id"
    t.boolean "with_pages",   default: true
    t.integer "dimension_id"
    t.text    "primary_name"
  end

  add_index "standard_base_documents", ["consumer_id"], name: "index_standard_base_documents_on_consumer_id", using: :btree
  add_index "standard_base_documents", ["id"], name: "index_standard_base_documents_on_id", unique: true, using: :btree

  create_table "standard_categories", force: :cascade do |t|
    t.string  "name"
    t.integer "consumer_id"
  end

  create_table "standard_document_field_owners", force: :cascade do |t|
    t.integer  "standard_document_field_id"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
  end

  add_index "standard_document_field_owners", ["owner_type", "owner_id"], name: "index_standard_document_field_owners_on_owner_type_and_owner_id", using: :btree
  add_index "standard_document_field_owners", ["standard_document_field_id", "owner_id", "owner_type"], name: "document_field_owners_index", unique: true, using: :btree

  create_table "standard_document_fields", force: :cascade do |t|
    t.integer "standard_document_id"
    t.string  "name"
    t.string  "data_type"
    t.integer "field_id",             default: "nextval('standard_document_fields_field_id_seq'::regclass)", null: false
    t.integer "min_year"
    t.integer "max_year"
    t.string  "type"
    t.boolean "notify",               default: false
    t.boolean "encryption",           default: false
    t.integer "created_by_user_id"
    t.integer "document_id"
    t.text    "speech_text"
    t.text    "speech_text_contact"
    t.boolean "primary_descriptor",   default: false
    t.boolean "suggestions"
    t.text    "data_type_values"
  end

  create_table "standard_folder_standard_documents", force: :cascade do |t|
    t.integer "standard_folder_id"
    t.integer "standard_base_document_id"
    t.integer "rank"
  end

  create_table "standard_groups", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "consumer_id"
  end

  add_index "standard_groups", ["name"], name: "index_standard_groups_on_name", unique: true, using: :btree

  create_table "subscribers", force: :cascade do |t|
    t.string   "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "subscription_type"
    t.datetime "subscription_expires_at"
    t.integer  "user_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.string   "subscription_token"
  end

  add_index "subscriptions", ["user_id"], name: "index_subscriptions_on_user_id", using: :btree

  create_table "symmetric_key_archives", force: :cascade do |t|
    t.integer  "created_for_user_id"
    t.integer  "created_by_user_id"
    t.integer  "document_id"
    t.datetime "symmetric_key_created_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "symmetric_keys", force: :cascade do |t|
    t.integer  "created_for_user_id"
    t.integer  "created_by_user_id"
    t.text     "key_encrypted"
    t.integer  "document_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "iv_encrypted"
  end

  add_index "symmetric_keys", ["created_for_user_id", "document_id"], name: "symmetric_keys_bi_index", unique: true, using: :btree
  add_index "symmetric_keys", ["document_id"], name: "index_symmetric_keys_on_document_id", unique: true, where: "(created_for_user_id IS NULL)", using: :btree

  create_table "user_accesses", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "accessor_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_accesses", ["user_id", "accessor_id"], name: "index_user_accesses_on_user_id_and_accessor_id", using: :btree

  create_table "user_contact_lists", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "state"
    t.integer  "uploaded_offset", default: 0
    t.integer  "max_entries",     default: 0
    t.string   "type"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "user_contact_lists", ["user_id"], name: "index_user_contact_lists_on_user_id", using: :btree

  create_table "user_contacts", force: :cascade do |t|
    t.text     "name"
    t.text     "emails"
    t.text     "phones"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "user_contact_list_id"
  end

  add_index "user_contacts", ["user_contact_list_id"], name: "index_user_contacts_on_user_contact_list_id", using: :btree

  create_table "user_credit_promotions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "given_by_id"
    t.float    "credit_value",   default: 0.0
    t.string   "promotion_type"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "user_credit_promotions", ["given_by_id"], name: "index_user_credit_promotions_on_given_by_id", using: :btree
  add_index "user_credit_promotions", ["user_id"], name: "index_user_credit_promotions_on_user_id", using: :btree

  create_table "user_credit_transactions", force: :cascade do |t|
    t.integer  "user_credit_id"
    t.integer  "transactionable_id"
    t.string   "transactionable_type"
    t.integer  "fax_balance",            default: 0
    t.string   "state"
    t.string   "transaction_identifier"
    t.datetime "transaction_date"
    t.datetime "created_at",                           null: false
    t.datetime "updated_at",                           null: false
    t.float    "dollar_balance",         default: 0.0
    t.integer  "pages_balance",          default: 0
  end

  add_index "user_credit_transactions", ["state"], name: "index_user_credit_transactions_on_state", using: :btree
  add_index "user_credit_transactions", ["transactionable_id", "transactionable_type"], name: "idx_credit_transactionable", using: :btree
  add_index "user_credit_transactions", ["user_credit_id"], name: "index_user_credit_transactions_on_user_credit_id", using: :btree

  create_table "user_credits", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "fax_credit",    default: 0
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.float    "dollar_credit", default: 0.0
    t.integer  "pages_credit",  default: 0
  end

  add_index "user_credits", ["user_id"], name: "index_user_credits_on_user_id", using: :btree

  create_table "user_document_caches", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "version",                 default: 0
    t.text     "encrypted_password_hash"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "mobile_app_version"
  end

  add_index "user_document_caches", ["user_id"], name: "index_user_document_caches_on_user_id", using: :btree
  add_index "user_document_caches", ["version"], name: "index_user_document_caches_on_version", using: :btree

  create_table "user_folder_settings", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "folder_owner_id"
    t.string   "folder_owner_type"
    t.integer  "standard_base_document_id"
    t.boolean  "displayed",                 default: true
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  add_index "user_folder_settings", ["displayed"], name: "index_user_folder_settings_on_displayed", using: :btree
  add_index "user_folder_settings", ["folder_owner_id", "folder_owner_type"], name: "user_setting_folders_owner_idx", using: :btree
  add_index "user_folder_settings", ["standard_base_document_id"], name: "index_user_folder_settings_on_standard_base_document_id", using: :btree
  add_index "user_folder_settings", ["user_id", "standard_base_document_id"], name: "user_setting_folders_idx", using: :btree
  add_index "user_folder_settings", ["user_id"], name: "index_user_folder_settings_on_user_id", using: :btree

  create_table "user_migrations", force: :cascade do |t|
    t.boolean  "img_to_pdf_conversion_done",          default: true
    t.integer  "user_id"
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
    t.boolean  "first_page_thumbnail_migration_done", default: false
  end

  create_table "user_statistics", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "last_logged_in_web_app"
    t.datetime "last_logged_in_iphone_app"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.datetime "last_logged_in_alexa"
  end

  add_index "user_statistics", ["last_logged_in_iphone_app"], name: "index_user_statistics_on_last_logged_in_iphone_app", using: :btree
  add_index "user_statistics", ["last_logged_in_web_app"], name: "index_user_statistics_on_last_logged_in_web_app", using: :btree
  add_index "user_statistics", ["user_id"], name: "index_user_statistics_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email"
    t.string   "encrypted_pin"
    t.string   "salt"
    t.text     "private_key"
    t.text     "public_key"
    t.string   "phone"
    t.string   "phone_normalized"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "phone_confirmed_at"
    t.string   "phone_confirmation_token"
    t.datetime "phone_confirmation_sent_at"
    t.string   "forgot_pin_token"
    t.datetime "forgot_pin_token_sent_at"
    t.datetime "forgot_pin_confirmed_at"
    t.integer  "total_storage_size",               limit: 8, default: 0
    t.integer  "total_pages_count",                          default: 0
    t.integer  "limit_storage_size",               limit: 8, default: 5368709120
    t.integer  "limit_pages_count",                          default: 1000
    t.string   "email_confirmation_token"
    t.datetime "email_confirmed_at"
    t.datetime "email_confirmation_sent_at"
    t.string   "encrypted_password",                         default: "",         null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string   "authentication_token"
    t.string   "first_name"
    t.string   "middle_name"
    t.string   "last_name"
    t.boolean  "fields_encryption_migration_done",           default: true
    t.integer  "standard_category_id"
    t.integer  "consumer_account_type_id"
    t.string   "upload_email"
    t.date     "birthday"
    t.datetime "password_updated_at"
    t.string   "unverified_email"
    t.string   "unverified_phone"
    t.string   "mobile_app_version"
    t.text     "password_private_key"
    t.string   "auth_token_private_key"
    t.datetime "last_time_notifications_read_at"
    t.integer  "business_information_id"
    t.string   "oauth_token_private_key"
    t.datetime "web_phone_confirmed_at"
    t.string   "web_phone_confirmation_token"
    t.datetime "web_phone_confirmation_sent_at"
    t.integer  "current_workspace_id"
    t.integer  "referrer_id"
    t.string   "current_workspace_name"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
  add_index "users", ["created_at"], name: "index_users_on_created_at", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["phone_confirmation_token"], name: "index_users_on_phone_confirmation_token", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "workflow_document_uploads", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "document_id"
    t.integer  "workflow_standard_document_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "workflow_document_uploads", ["document_id"], name: "index_workflow_document_uploads_on_document_id", using: :btree
  add_index "workflow_document_uploads", ["user_id"], name: "index_workflow_document_uploads_on_user_id", using: :btree
  add_index "workflow_document_uploads", ["workflow_standard_document_id"], name: "index_workflow_standard_document_id", using: :btree

  create_table "workflow_standard_documents", force: :cascade do |t|
    t.integer  "standard_document_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "ownerable_type"
    t.integer  "ownerable_id"
  end

  add_index "workflow_standard_documents", ["standard_document_id"], name: "index_workflow_standard_documents_on_standard_document_id", using: :btree

  create_table "workflows", force: :cascade do |t|
    t.string   "name"
    t.integer  "admin_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.datetime "end_date"
    t.string   "status"
    t.integer  "expected_documents_count"
    t.string   "purpose"
  end

  add_index "workflows", ["admin_id"], name: "index_workflows_on_admin_id", using: :btree

  add_foreign_key "business_documents", "businesses"
  add_foreign_key "business_documents", "documents"
  add_foreign_key "business_informations", "standard_categories"
  add_foreign_key "business_partners", "businesses"
  add_foreign_key "business_partners", "users"
  add_foreign_key "clients", "businesses"
  add_foreign_key "credit_cards", "users"
  add_foreign_key "document_access_requests", "documents"
  add_foreign_key "document_permissions", "documents"
  add_foreign_key "document_permissions", "users"
  add_foreign_key "docyt_bot_user_questions", "users"
  add_foreign_key "emails", "businesses"
  add_foreign_key "group_users", "businesses"
  add_foreign_key "invitations", "clients"
  add_foreign_key "invitations", "group_users"
  add_foreign_key "notify_durations", "standard_document_fields"
  add_foreign_key "payment_transactions", "users"
  add_foreign_key "permissions", "standard_base_documents"
  add_foreign_key "permissions", "users"
  add_foreign_key "referral_codes", "users"
  add_foreign_key "reviews", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "user_contact_lists", "users"
  add_foreign_key "user_contacts", "user_contact_lists"
  add_foreign_key "user_credit_promotions", "users"
  add_foreign_key "user_credit_transactions", "user_credits"
  add_foreign_key "user_credits", "users"
  add_foreign_key "user_document_caches", "users"
  add_foreign_key "user_folder_settings", "users"
  add_foreign_key "user_statistics", "users"
end
