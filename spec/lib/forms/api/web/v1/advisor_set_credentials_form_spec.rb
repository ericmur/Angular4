require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::AdvisorSetCredentialsForm do
  before do
    load_standard_documents
    load_docyt_support
  end

  context "#save" do
    let!(:set_credentials_form) { Api::Web::V1::AdvisorSetCredentialsForm }

    let!(:advisor) { create(:advisor) }

    let!(:pincode) { Faker::Number.number(5) }

    let!(:unverified_email) { Faker::Internet.email }

    let!(:password)       { Faker::Internet.password(8) }
    let!(:short_password) { Faker::Number.number(4) }

    let(:valid_save_params) {
      {
        id: advisor.id,
        pincode: pincode,
        password: password,
        password_confirmation: password
      }
    }

    let(:invalid_save_params) {
      {
        id: advisor.id,
        pincode: pincode,
        password: short_password,
        password_confirmation: short_password,
        unverified_email: "@#{unverified_email}@"
      }
    }

    it 'should save form with unverified email' do
      set_credentials_form.new(valid_save_params.merge(unverified_email: unverified_email)).save

      advisor.reload

      expect(advisor.unverified_email).to eq(unverified_email)
      expect(advisor.password_private_key).to_not be_nil
      expect(advisor.valid_password?(password)).to be_truthy
    end

    it 'should save form without unverified email' do
      set_credentials_form.new(valid_save_params).save

      advisor.reload

      expect(advisor.unverified_email).to be_nil
      expect(advisor.password_private_key).to_not be_nil
      expect(advisor.valid_password?(password)).to be_truthy
    end

    it 'should not save form with invalid params' do
      form = set_credentials_form.new(invalid_save_params)
      form.save

      expect(form.errors.messages.keys).to eq([:unverified_email, :password])
    end

  end

end
