require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::AvatarBuilder do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:service) { Api::Web::V1::AvatarBuilder }
  let!(:s3_object_key) { "#{Faker::Lorem.word}.jpg" }
  let!(:advisor) { create(:advisor) }
  let!(:advisor_with_avatar) { 
    advisor = create(:advisor)
    advisor.build_avatar(s3_object_key: s3_object_key)
    advisor.save
    advisor
  }

  context '#create_avatar' do
    after do
      expect(@avatar.s3_object_key).to eq nil
    end

    it 'should create avatar and return it' do
      expect {
        @avatar = service.new(advisor, {}).create_avatar
      }.to change(Avatar, :count).by(1)
    end

    it 'should recreate avatar for advisor with avatar and return it' do
      expect {
        @avatar = service.new(advisor_with_avatar, {}).create_avatar
      }.not_to change(Avatar, :count)
    end
  end

  context '#complete_avatar_upload' do
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

    it 'should update S3 path with valid params' do
      avatar = service.new(advisor_with_avatar, valid_upload_params).complete_avatar_upload
      
      expect(avatar.s3_object_key).to eq(valid_upload_params['s3_object_key'])
    end

    it 'should not update S3 path with invalid params' do
      avatar = service.new(advisor_with_avatar, invalid_upload_params).complete_avatar_upload
      
      expect(avatar.s3_object_key).not_to be_empty
      expect(avatar.errors.messages).to eq({:s3_object_key =>["S3 file path is not set"]})
    end
    
  end
end