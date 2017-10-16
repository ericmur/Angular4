require 'rails_helper'
require 'custom_spec_helper'

describe Api::Mobile::V2::BusinessesController do
  before do
    stub_docyt_support_creation
    load_standard_documents
    load_startup_keys
    setup_logged_in_consumer(consumer, pin)
    ConsumerAccountType.load
  end

  let!(:pin)    { Faker::Number.number(6) }
  let!(:consumer)         { create(:consumer, :pin => pin, :pin_confirmation => pin) }
  let!(:standard_category) { create(:standard_category) }

  context "#create" do
    let(:valid_business_params) {
      {
        'name' =>  Faker::Name.name,
        'entity_type' =>  Faker::Commerce.product_name,
        'address_zip' =>  Faker::Address.zip,
        'address_city' =>  Faker::Address.city,
        'address_state' =>  Faker::Address.state,
        'address_street' =>  Faker::Address.street_address,
        'standard_category_id' => standard_category.id,
      }
    }

    it 'should successfully create business' do
      expect {
        post :create, format: :json, device_uuid: @device.device_uuid, password_hash: @hsh, business: valid_business_params
      }.to change{ Business.count }.by(1)

      business = Business.first
      expect(business.business_partners.where(user: consumer).exists?).to eq(true)
    end
  end

end
