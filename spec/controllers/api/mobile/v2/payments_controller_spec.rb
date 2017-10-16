require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Mobile::V2::PaymentsController do
  before do
    stub_docyt_support_creation
    load_startup_keys
    setup_logged_in_consumer(consumer, pin)
  end

  let!(:pin)       { Faker::Number.number(6) }
  let!(:consumer)  { create(:consumer, :pin => pin, :pin_confirmation => pin) }
  let!(:fax_page_one) { FactoryGirl.create(:fax_page_one) }

  context "#sk_payment_callback" do
    it 'should successfully create transaction' do
      post :sk_payment_callback, format: :json,
        product_identifier: 'docytTest.Docyt.Consumable.FaxPage1', 
        device_uuid: @device.device_uuid, 
        password_hash: @hsh,
        transaction_date: "2016-12-18 11:44:28 +0000", 
        transaction_identifier: "1000000259889679"

      expect(consumer.user_credit.fax_credit).to eq(1)
    end
  end
end