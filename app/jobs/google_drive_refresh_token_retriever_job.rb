class GoogleDriveRefreshTokenRetrieverJob < ActiveJob::Base
  queue_as :high

  def perform(auth_code, uid, user_id, path, path_display_name = nil)
    user = User.find_by_id(user_id)
    consumer = User.find_by_id(user_id)

    cloud_service_auth = save_cloud_service_auth!(auth_code, uid, user)

    cloud_service_path = consumer.find_or_create_cloud_service_path(:cloud_service_authorization_id => cloud_service_auth.id, :path => path, :path_display_name => path_display_name)
    cloud_service_path.sync_data
  end

  private
  def cloud_service
    @cloud_service ||= CloudService.google_drive
  end
  
  def save_cloud_service_auth!(auth_code, uid, user)
    cloud_service_auth = user.cloud_service_authorizations.where(:uid => uid, :cloud_service_id => cloud_service.id).first
    if cloud_service_auth
      #Check if new auth_code returns a valid token. Only if it does do we overwrite the entry in DB. The Google API will not return a valid token if auth code has already been used in the past to get a refresh token.
      begin
        cloud_service_auth.token = GoogleDriveRefreshTokenRetriever.new(auth_code).renew_refresh_token
        cloud_service_auth.save!
      rescue Signet::AuthorizationError => e
        puts "Error retrieving GDrive token for #{uid} for user.id: #{user.id}: #{e.to_s}"
        error_json = JSON.parse(e.response.body)
        if error_json['error'] == "invalid_grant"
          if error_json["error_description"].match(/already redeemed/)
            return cloud_service_auth
          else
            raise e
          end
        else
          raise e
        end
      end
    else
      cloud_service_auth = user.cloud_service_authorizations.build(:uid => uid, :cloud_service_id => cloud_service.id)
      cloud_service_auth.token = GoogleDriveRefreshTokenRetriever.new(auth_code).renew_refresh_token
      cloud_service_auth.save!
    end
    cloud_service_auth
  end
end
