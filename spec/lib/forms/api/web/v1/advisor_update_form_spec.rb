require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::AdvisorUpdateForm do

  context "#save" do
    before do
      load_standard_documents
      load_docyt_support
    end

    let!(:advisor_form)     { Api::Web::V1::AdvisorUpdateForm }
    let!(:current_password) { Faker::Lorem.characters(8) }
    let!(:new_password)     { Faker::Lorem.characters(8) }
    let!(:short_password)   { Faker::Lorem.characters(4) }
    let!(:other_advisor)    { create(:advisor) }
    let!(:advisor) {
      advisor = create(:advisor)
      advisor.password = current_password
      advisor.save
      advisor
    }

    let(:name_update_params) {
      {
        'id' => advisor.id,
        'first_name' => Faker::Name.first_name,
        'middle_name' => "",
        'last_name' => Faker::Name.last_name
      }
    }

    let(:invalid_update_params) {
      {
        'first_name' => Faker::Name.first_name,
        'middle_name' => "",
        'last_name' => Faker::Name.last_name
      }
    }

    let(:email_update_params) {
      {
        'id' => advisor.id,
        'unverified_email' => Faker::Internet.email
      }
    }

    let(:invalid_email_update_params) {
      {
        'id' => advisor.id,
        'unverified_email' => "@#{Faker::Internet.email}@"
      }
    }

    let(:existing_email_update_params) {
      {
        'id' => advisor.id,
        'unverified_email' => other_advisor.email
      }
    }

    let(:password_update_params) {
      {
        'id' => advisor.id,
        'current_password' => current_password,
        'password' => new_password,
        'password_confirmation' => new_password
      }
    }

    let(:wrong_current_password_update_params) {
      {
        'id' => advisor.id,
        'current_password' => new_password,
        'password' => new_password,
        'password_confirmation' => new_password
      }
    }

    let(:invalid_new_password_update_params) {
      {
        'id' => advisor.id,
        'current_password' => current_password,
        'password' => short_password,
        'password_confirmation' => short_password
      }
    }

    let(:current_workspace_update_params) {
      {
        'id' => advisor.id,
        'current_workspace_id' => [ConsumerAccountType::BUSINESS, ConsumerAccountType::INDIVIDUAL].sample
      }
    }

    let(:standard_category_update_params) {
      {
        'id' => advisor.id,
        'standard_category_id' => StandardCategory.first.id
      }
    }

    it 'should update names' do
      @form = advisor_form.new(name_update_params)

      expect(@form.save).to be true

      expect(@form.to_model.first_name).to eq(name_update_params['first_name'])
      expect(@form.to_model.middle_name).to eq(name_update_params['middle_name'])
      expect(@form.to_model.last_name).to eq(name_update_params['last_name'])
    end

    it 'should not update without id' do
      @form = advisor_form.new(invalid_update_params)

      expect(@form.save).to be false
      expect(@form.errors).not_to be_empty
    end

    it 'should update email' do
      @form = advisor_form.new(email_update_params)

      expect(@form.save).to be true
      expect(@form.to_model.unverified_email).to eq(email_update_params['unverified_email'])
    end

    it 'should not update advisor with invalid email' do
      @form = advisor_form.new(invalid_email_update_params)

      expect(@form.save).to be false

      expect(@form.to_model.unverified_email).not_to eq(invalid_email_update_params['unverified_email'])
      expect(@form.errors).not_to be_empty
    end

    it 'should not update advisor with existing email' do
      @form = advisor_form.new(existing_email_update_params)

      expect(@form.save).to be false

      expect(@form.to_model.unverified_email).not_to eq(existing_email_update_params['unverified_email'])
      expect(@form.errors).not_to be_empty
    end

    it 'should update password' do
      @form = advisor_form.new(password_update_params)

      password_updated_at = @form.to_model.password_updated_at

      expect(@form.save).to be true

      expect(@form.to_model.password_updated_at).not_to eq password_updated_at
      expect(@form.to_model.valid_password? current_password).to be false
    end

    it 'should update standard category id' do
      @form = advisor_form.new(standard_category_update_params)

      expect(@form.save).to be true
      expect(@form.to_model.standard_category_id).to eq(standard_category_update_params['standard_category_id'])
    end

    it 'should update current workspace id' do
      @form = advisor_form.new(current_workspace_update_params)

      expect(@form.save).to be true
      expect(@form.to_model.current_workspace_id).to eq(current_workspace_update_params['current_workspace_id'])
    end

    it 'should not update advisor with wrong current password' do
      @form = advisor_form.new(wrong_current_password_update_params)

      password_updated_at = @form.to_model.password_updated_at

      expect(@form.save).to be false

      expect(@form.to_model.password_updated_at).to eq password_updated_at
      expect(@form.to_model.valid_password? current_password).to be true
      expect(@form.errors).not_to be_empty
    end

    it 'should not update advisor with invalid new password' do
      @form = advisor_form.new(invalid_new_password_update_params)

      password_updated_at = @form.to_model.password_updated_at

      expect(@form.save).to be false

      expect(@form.to_model.password_updated_at).to eq password_updated_at
      expect(@form.to_model.valid_password? current_password).to be true
      expect(@form.errors).not_to be_empty
    end
  end
end
