require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe CloudServiceAuthorizationsController, :type => :controller do
  let(:cloud_service) { CloudService.first }
  
  before(:each) do
    load_standard_documents
    load_docyt_support
    setup_logged_in_consumer
    
    load_startup_keys
    unless @google_drive = CloudService.find_by_name(CloudService::GOOGLE_DRIVE)
      @google_drive = create(:cloud_service, :name => CloudService::GOOGLE_DRIVE)
    end
    unless @dropbox = CloudService.find_by_name(CloudService::DROPBOX)
      @dropbox = create(:cloud_service, :name => CloudService::DROPBOX)
    end

    @auth_data = {
      format: :json,
      pin: @user_pin,
      device_uuid: @device.device_uuid
    }
  end

  context 'create' do
    def post_data(token, cloud_service_id, uid)
      if @google_drive and cloud_service_id == @google_drive.id
        @google_drive_token = Faker::Lorem.characters(64)
        allow_any_instance_of(GoogleDriveRefreshTokenRetriever).to receive(:renew_refresh_token).and_return(@google_drive_token)
        @auth_data.merge({
                           cloud_service_authorization: {
                             cloud_service_id: cloud_service_id,
                             auth_code: token,
                             uid: uid,
                             path: 'base_folder',
                             path_display_name: 'base_folder'
                           }
                         })
      else
        @auth_data.merge({
                           cloud_service_authorization: {
                             cloud_service_id: cloud_service_id,
                             token: token,
                             uid: uid,
                             path: 'base_folder'
                           }
                         })
      end
    end

    it 'success' do
      token = Faker::Lorem.characters(64)
      if cloud_service.id == @google_drive.id
        expect(GoogleDriveRefreshTokenRetrieverJob).to receive(:perform_later)
      end
      
      post :create, post_data(token, cloud_service.id, 'vlad@docyt.com')

      expect(response.status).to eq(200)
      response_data = JSON.parse(response.body)
      expect(response_data['success']).to be

      if cloud_service.id != @google_drive.id
        expect(CloudServiceAuthorization.last.token).to eq(token)
      end
    end

    it 'wont dublicate the cloud service authorization if it already exists' do
      service_authorization = create(:cloud_service_authorization, user: @user, cloud_service: @dropbox)
      post :create, post_data(service_authorization.token, service_authorization.cloud_service.id, 'vlad@docyt.com')

      expect(response.status).to eq(200)
      response_data = JSON.parse(response.body)
    end

    it 'will update the token in cloud service authorization if it already exists'

    it 'will create cloud_service_path to scan'

    it 'will not duplicate cloud_service_path if it already exists but force a rescan on it'

    
  end
end
