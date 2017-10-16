Rails.application.routes.draw do

  get 'stubs/:template', to: 'stubs#show', as: 'stubs_template'
  get 'stubs/:folder/:template', to: 'stubs#show', as: 'nested_stubs_template'
  get 'stubs/:layout/:folder/:template', to: 'stubs#show', as: 'layout_nested_stubs_template'

  use_doorkeeper

  # Authentication for web-api

  namespace :api, defaults: { format: 'json' } do
    namespace :mobile do
      namespace :v2 do
        resources :docyt_bot_sessions, only: [:index] do
          collection do
            delete :destroy
            get :view_all
            get :samples
          end
        end
        resource :review, only: [:show, :create]
        resources :aliases, only: [:index]
        resources :field_value_suggestions, only: [:index]
        resources :businesses, only: [:index, :create, :show]
        resources :document_caches, only: [] do
          collection do
            get :check_version
          end
        end
        resources :standard_categories, only: [:create]
        resources :standard_base_documents, only: [:destroy] do
          member do
            put :set_displayed
            put :set_hidden
          end
        end
        resources :standard_documents, only: [:index, :create, :update] do
          member do
            put :update_fields
          end
        end
        resources :standard_folders, only: [:index, :create]
        resources :business_informations, only: [:create]
        resources :clients, only: [:create, :update, :show, :destroy] do
          member do
            put :unlink
          end
        end
        resources :client_invitations, only: [:create, :destroy] do
          member do
            post :recreate
          end
        end
        resources :documents, only: [:index] do
          collection do
            get :check_status
          end
          member do
            get :owners
            get :sharees
          end
        end
        resources :faxes, only: [:index, :show, :create] do
          member do
            put :retry
            get :check_status
          end
        end
        resources :secure_documents, only: [:index]
        resources :user_folder_settings, only: [:index]
        resources :payments, only: [] do
          collection do
            post :sk_payment_callback
          end
        end
      end
    end
    namespace :web do
      namespace :v1 do

        #post "payments/hook"
        resources :payments, only: [] do
          collection do
            post :webhook
          end
        end
        devise_scope :advisor do
          post    'sign_in'  => 'sessions#create',  as: 'advisor_session'
          delete  'sign_out' => 'sessions#destroy', as: 'destroy_advisor_session'

          post    'sign_up'  => 'advisors#create',  as: 'advisor_registration'
        end

        resources :advisors, :path => 'advisor', :only => [:update] do
          collection do
            post 'add_phone_number'
            put  'confirm_phone_number'
            put  'confirm_web_phone'
            put  'confirm_pincode'
            put  'confirm_credentials'
            get  'search'               => 'advisors#search'
            get  'send_phone_token'     => 'advisors#send_phone_token'
            get  'current_advisor'      => 'advisors#get_current_advisor'
            get  'advisor_types'        => 'advisors#get_advisor_types'
            get  'entity_types'         => 'advisors#get_entity_types'
            get  'documents_via_email'  => 'documents#documents_via_email'

            get  'resend_email_confirmation' => 'advisors#resend_email_confirmation'

            resources :notifications, :only => [:index]
            resources :documents, controller: 'advisors/documents' do
              collection do
                get  'documents_via_email'
              end
              member do
                get  'document_via_email'
              end
            end
          end

          resources :avatars, :path => 'avatar', :only => [:create] do
            put 'complete_upload', on: :collection
          end
        end

        resources :chats,           only: [:index, :show]
        resources :workflows,       only: [:index, :show, :create]
        resources :standard_groups, only: [:index]

        resources :consumer_account_types, only: :index

        resources :businesses, only: [:index, :show, :create, :update] do
          collection do
            get 'get_entity_types'
          end
        end

        resources :subscriptions, only: [:index, :create]

        resources :credit_cards, only: [:index, :show, :create, :update]

        resources :messages, only: [:index] do
          collection do
            get 'search'
          end
        end

        resources :contacts, only: [:index, :show, :create]

        resources :clients,  :only => [:index, :show, :create] do
          collection do
            get 'search'
          end

          resources :invitations, only: [:create, :destroy]
        end

        resources :standard_folders,   only: [:index, :show]
        resources :standard_documents, only: [:index, :show]

        resources :documents, :only => [:index, :show, :create, :destroy] do
          resources :document_fields, only: [:index]

          collection do
            get 'search'
            put 'assign'
          end

          member do
            put 'complete_upload'
            put 'update_category'
          end
        end

        resources :documents, only: [] do
          resources :document_field_values, only: [:create, :update]
        end
      end
    end

    namespace :categorization do
      namespace :v1 do
        resources :docyt_bot_categorizations, only: [] do
          collection do
            post :update_document_type
          end
        end
      end
    end
  end

  resources :users, :only => [:create, :show] do
    collection do
      post 'check'
      post 'forgot_pin'
      post 'authenticate_password'
      post 'authenticate_phone_or_device'
      post 'create_pin'
      get 'email_confirmation'
      post 'set_notifications_read_at'
      post 'set_messages_read_at'
      post 'resend_phone_confirmation_code'
      post 'resend_new_device_code'
    end
  end

  resources :notifications, only: [:index, :destroy] do
    member do
      put :mark_as_read
    end
  end

  resources :email_confirmations, only: [:new] do
    collection do
      get 'confirm'
      get 'completed'
      post 'resend_confirmation'
    end
  end

  match "email_confirmations/:token" => "email_confirmations#confirm", as: :confirm_email_confirmation, via: [:get, :post]
  get "app_launcher" => "home#app_launcher", as: :app_launcher
  get "missed_messages/:chat_id/:receiver_id/:sender_id" => "home#missed_messages", as: :missed_messages
  get "invite/:referral_code" => "invitations#referral", as: :referral_invite

  resources :oauth_sessions, only: [:new, :create, :destroy]

  resources :advisors, only: [:show] do
    member do
      get :documents
    end
  end
  resources :subscribers, :only => [:create]
  resources :documents, :only => [:index, :create, :show, :destroy, :update] do
    member do
      put 'share', 'revoke', 'start_upload', 'complete_upload', 'update_sharees', 'update_owners', 'share_with_system'
      get 'sharees', 'owners', 'object_keys', 'info', 'symmetric_key'
    end
    collection do
      get 'search', 'suggested'
      post 'group_reorder'
      post :sns_notification
    end
    resources :pages, only: [:create, :show, :destroy], shallow: true do

      member do
        put 'start_upload', 'complete_upload', 'reupload', 'check_pending_upload'
      end
    end
  end
  resources :document_access_requests, only: [:index] do
    collection do
      post :request_access
      post :approve_request
    end
  end
  resources :document_upload_emails, only: [:create]
  resources :chat_messages, only: [:show]

  resources :standard_base_documents, only: [:index, :create, :update, :destroy] do
    member do
      put :set_hidden
      put :set_displayed
    end
  end
  resources :standard_folders, only: [:create, :destroy] do
    member do
      put :set_hidden
      put :set_displayed
    end
  end
  resources :document_fields, only: [:create, :destroy]
  resources :pages, only: [] do
    collection do
      post 'reorder'
      post :sns_notification
    end
    member do
      get 'object_keys'
    end
  end

  resources :favorites, :only => [:index, :create, :destroy] do
    collection do
      post 'bulk_create'
    end
  end

  resources :document_field_values, only: [:create, :update, :destroy]

  resources :devices, only: [:index, :destroy]
  resources :push_devices, only: [:create]

  resources :groups, :only => [:create] do
    resources :group_users, :only => [:index, :create, :show, :update, :destroy], shallow: true do
      member do
        put 'share_with_advisor'
        put 'revoke_share_with_advisor'
        put 'set_user'
        put 'unlink'
      end
    end
  end
  resources :invitations, only: [:create, :show] do
    collection do
      get 'first_time_invitations'
    end
    member do
      put 'accept'
      put 'reject'
      put 'cancel'
      put 'reinvite'
    end
  end
  get 'i/:token' => 'invitations#preview', as: :preview_invitation

  resources :avatars, only: [:create] do
    collection do
      post 'complete_upload'
    end
  end

  namespace :api, defaults: { format: 'json' } do
    namespace :alexa do
      namespace :v1 do
        resources :sessions, :only => [:destroy] do
          member do
            get 'welcome'
            post 'add_device'
            post 'confirm_device'
            post 'verify_passcode'
            post 'set_passcode'
          end
        end

        resources :intents, only: [] do
          collection do
            get :get_field_value
            get :get_expiring_docs
            get :get_due_docs
          end
        end
      end
    end
  end

  resource :account do
    member do
      get 'quick_refresh'
      put 'allow_access'
      put 'remove_access'
      put 'resend_phone_confirmation_code'
      put 'resend_new_device_code'
      put 'add_device'
      put 'confirm_device'
      put 'confirm_phone_number'
      put 'update_email'
      get 'validate_pin'
      put 'update_pin'
      post 'check_limit'
      put 'update_avatar'
      post 'reupload_avatar'
      put 'download_exhausted'
      post 'check_credit_limit'
    end
  end

  resources :locations, only: [:create]

  resources :user_contacts, only: [] do
    post 'import', on: :collection
  end

  get 'policy' => 'home#policy', as: :policy
  get 'privacy' => 'home#privacy', as: :privacy
  get 'terms' => 'home#terms', as: :terms

  get 'features' => 'home#features'
  get 'security' => 'home#security'
  get 'about' => 'home#about'
  get 'pricing' => 'home#pricing'
  root 'home#index'

  resources :cloud_service_authorizations, only: [:create]
  resources :emails, only: [] do
    post :sns_notification, on: :collection
  end

  get "*path" => "backbone_app#app" # this is a catch-all route that will route all missing request to backbone app router


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
