require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Mobile::V2::ReviewsController do
  before do
    load_standard_documents
    load_docyt_support
    load_startup_keys
    setup_logged_in_consumer(consumer, pin)
  end

  let!(:old_app_version) { '1.2.1' }
  let!(:app_version) { '1.2.3' }
  let!(:pin)       { Faker::Number.number(6) }
  let!(:consumer)  { create(:consumer, :pin => pin, :pin_confirmation => pin) }

  context "#show" do
    context "check eligible" do
      it 'should ask for review' do
        ca = CloudServiceAuthorization.all.sample
        FactoryGirl.create(:document, :with_owner, cloud_service_authorization: ca, consumer_id: consumer.id)
        FactoryGirl.create(:document, :with_owner, cloud_service_authorization: ca, consumer_id: consumer.id)
        FactoryGirl.create(:document, :with_owner, cloud_service_authorization: ca, consumer_id: consumer.id)

        get :show, format: :json, device_uuid: @device.device_uuid, app_version: app_version
        expect(response.status).to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json["ask_for_review"]).to eq(true)
      end

      it 'should not ask for review' do
        get :show, format: :json, device_uuid: @device.device_uuid, app_version: app_version
        expect(response.status).to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json["ask_for_review"]).to eq(false)
      end
    end

    context "for eligible user" do
      before do
        allow_any_instance_of(User).to receive(:eligible_to_review?).and_return(true)
      end

      it 'shoud not ask for review when user already review current version app' do
        FactoryGirl.create(:review, user: consumer, refused: false, last_version: app_version)
        get :show, format: :json, device_uuid: @device.device_uuid, app_version: app_version
        expect(response.status).to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json["ask_for_review"]).to eq(false)
      end

      xit 'shoud ask for review when user have not review current version app' do
        FactoryGirl.create(:review, user: consumer, refused: false, last_version: old_app_version)
        get :show, format: :json, device_uuid: @device.device_uuid, app_version: app_version
        expect(response.status).to eq(200)
        response_json = JSON.parse(response.body)
        expect(response_json["ask_for_review"]).to eq(true)
      end
    end
  end

  context "#create", focus: true do
    it 'should create review with refused=1' do
      post :create, format: :json, device_uuid: @device.device_uuid, app_version: app_version, refused: 1
      expect(response.status).to eq(200)
      expect(Review.count).to eq(1)
      expect(consumer.review.refused).to eq(true)
    end

    it 'should create review with refused=true' do
      post :create, format: :json, device_uuid: @device.device_uuid, app_version: app_version, refused: true
      expect(response.status).to eq(200)
      expect(Review.count).to eq(1)
      expect(consumer.review.refused).to eq(true)
    end

    it 'should create review with refused=false' do
      post :create, format: :json, device_uuid: @device.device_uuid, app_version: app_version, refused: 0
      expect(response.status).to eq(200)
      expect(Review.count).to eq(1)
      expect(consumer.review.refused).to eq(false)
    end

    it 'should recreate for latest version' do
      FactoryGirl.create(:review, user: consumer, refused: false, last_version: old_app_version)
      post :create, format: :json, device_uuid: @device.device_uuid, app_version: app_version
      expect(response.status).to eq(200)
      expect(Review.count).to eq(1)
      expect(consumer.review.refused).to eq(false)
    end
  end
end
