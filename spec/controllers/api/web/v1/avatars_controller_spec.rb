require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::AvatarsController do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:s3_object_key) { "#{Faker::Lorem.word}.jpg" }
  let!(:advisor_with_avatar) {
    advisor = create(:advisor)
    advisor.build_avatar(s3_object_key: s3_object_key)
    advisor.save
    advisor
  }

  context '#create' do
    let!(:advisor) { create(:advisor) }

    it 'should create and return avatar for advisor without avatar' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        xhr :post, :create, advisor_id: advisor.id, avatar_type: 'user'
      }.to change(Avatar, :count).by(1)

      expect(JSON.parse(response.body)).to include('avatar')
      expect(response).to have_http_status(201)
    end

    it 'should recreate and return avatar for advisor with avatar' do
      request.headers['X-USER-TOKEN'] = advisor_with_avatar.authentication_token
      expect {
        xhr :post, :create, advisor_id: advisor_with_avatar.id, avatar_type: 'user'
      }.not_to change(Avatar, :count)

      avatar = JSON.parse(response.body)['avatar']

      expect(avatar['s3_object_key']).to eq nil
      expect(response).to have_http_status(201)
    end
  end

  context '#complete_upload' do
    let!(:avatar) {  }
    let(:valid_upload_params) {
      {
        "s3_object_key" => s3_object_key
      }
    }

    let(:invalid_upload_params) {
      {
        "s3_object_key" => ""
      }
    }

    it 'should update avatar path on s3 and return avatar with updated path when params valid' do
      request.headers['X-USER-TOKEN'] = advisor_with_avatar.authentication_token
      expect_any_instance_of(Avatar).to receive(:complete_upload!).and_call_original

      xhr :put, :complete_upload, { avatar: valid_upload_params, advisor_id: advisor_with_avatar.id,
        id: advisor_with_avatar.avatar.id, avatar_type: 'user' }

      avatar = JSON.parse(response.body)['avatar']
      expect(avatar['s3_object_key']).to eq(valid_upload_params['s3_object_key'])
      expect(response).to have_http_status(200)
    end

    it 'should not update and return avatar when params invalid' do
      request.headers['X-USER-TOKEN'] = advisor_with_avatar.authentication_token

      xhr :put, :complete_upload, { avatar: invalid_upload_params, advisor_id: advisor_with_avatar.id,
        id: advisor_with_avatar.avatar.id, avatar_type: 'user' }

      errors = JSON.parse(response.body)

      expect(errors).to eq({"s3_object_key" => ["S3 file path is not set"]})
      expect(response).to have_http_status(422)
    end
  end
end
