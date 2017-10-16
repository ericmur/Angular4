require 'rails_helper'
require 'custom_spec_helper'

describe Api::Mobile::V2::FaxesController do
  before do
    stub_request(:post, /.phaxio.com/).to_return(status: 200)
    stub_docyt_support_creation
    load_startup_keys
    setup_logged_in_consumer(consumer, pin)
  end

  let!(:pin)    { Faker::Number.number(6) }
  let!(:consumer)         { create(:consumer, :pin => pin, :pin_confirmation => pin) }
  let!(:another_consumer) { create(:consumer, :pin => pin, :pin_confirmation => pin) }
  let!(:third_consumer) { create(:consumer, :pin => pin, :pin_confirmation => pin) }
  let!(:document)    { build(:document, :with_standard_document, uploader: consumer, cloud_service_authorization: CloudServiceAuthorization.all.sample) }
  let!(:another_document)    { create(:document, :with_standard_document, uploader: consumer, cloud_service_authorization: CloudServiceAuthorization.all.sample) }
  let!(:third_document)    { create(:document, :with_standard_document, uploader: another_consumer, cloud_service_authorization: CloudServiceAuthorization.all.sample) }
  let!(:fax)         { create(:fax, sender: consumer, document: another_document) }
  let!(:another_fax) { create(:fax, sender: another_consumer, document: third_document) }

  context "#index" do
    let!(:another_consumer) { create(:consumer) }

    it 'should return list of faxes' do
      get :index, format: :json, device_uuid: @device.device_uuid, password_hash: @hsh

      faxes_list = JSON.parse(response.body)["faxes"]

      expect(response.status).to eq(200)
      expect(faxes_list.size).to eq(1)
    end

    it 'should return empty list of faxes if another consumer' do
      setup_logged_in_consumer(third_consumer, @hsh)
      get :index, format: :json, device_uuid: @device.device_uuid, password_hash: @hsh

      faxes_list = JSON.parse(response.body)["faxes"]

      expect(response.status).to eq(200)
      expect(faxes_list.size).to eq(0)
    end

  end

  context '#show' do

    it 'should return fax if consumer have this fax' do
      get :show, format: :json, id: fax.id,  device_uuid: @device.device_uuid, password_hash: @hsh

      fax_response = JSON.parse(response.body)["fax"]

      expect(response.status).to eq(200)
      expect(fax_response['id']).to eq(fax.id)
    end

    it 'should not return fax if consumer has no such fax' do
      get :show, format: :json, id: another_fax.id,  device_uuid: @device.device_uuid, password_hash: @hsh

      expect(response.status).to eq(404)
    end

  end

  context '#create' do
    let(:valid_fax_params) {
      {
        'fax_number' => Faker::Number.number(10),
        'document_id' => document.id,
        'pages_count' => 1
      }
    }

    let!(:invalid_fax_params) {
      {
        'fax_number' => '',
        'document_id' => ''
      }
    }

    it 'should check user credit' do
      document.document_owners.new(owner: consumer)
      document.save

      page = document.pages.new
      page.name = 'Test'
      page.page_num = 1
      page.save

      expect {
        post :create, format: :json, device_uuid: @device.device_uuid, password_hash: @hsh, fax: valid_fax_params
      }.to change{ Fax.count }.by(0)

      expect(response.status).to eq(422)
      res_json = JSON.parse(response.body)
      expect(res_json['errors'].first).to include('You don\'t have enough credits to fax this document')
    end

    it 'should successfully create fax' do
      document.document_owners.new(owner: consumer)
      document.save

      page = document.pages.new
      page.name = 'Test'
      page.page_num = 1
      page.save

      fax_page_one = FactoryGirl.create(:fax_page_one)
      consumer.user_credit.purchase_fax_credit!(fax_page_one, fax_page_one.fax_credit_value, nil, nil)

      expect {
        post :create, format: :json, device_uuid: @device.device_uuid, password_hash: @hsh, fax: valid_fax_params
      }.to change{ Fax.count }.by(1)

      expect(response.status).to eq(200)
    end

    it 'should not create fax' do
      expect {
        post :create, format: :json, device_uuid: @device.device_uuid, password_hash: @hsh, fax: invalid_fax_params
      }.not_to change{ Fax.count }

      expect(response.status).to eq(422)
      res_json = JSON.parse(response.body)
      expect(res_json['errors'].first).to include('Unable to load document.')
    end
  end

end
