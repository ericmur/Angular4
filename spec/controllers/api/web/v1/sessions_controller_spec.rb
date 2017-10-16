require "rails_helper"
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::SessionsController do
  before(:each) do
    load_standard_documents
    load_docyt_support
  end

  let!(:advisor) { create(:advisor) }

  context 'create' do
    let(:valid_sign_in_params){
      {
        'email' => advisor.email,
        'password' => 'test_password'
      }
    }
    let(:invalid_sign_in_params){
      {
        'email' => Faker::Internet.email,
        'password' => Faker::Internet.password(8)
      }
    }

    it 'should successfuly login when params are valid' do
      xhr :post, :create, session: valid_sign_in_params
      expect(response).to have_http_status(200)

      current_advisor = JSON.parse(response.body)['advisor']
      expect(current_advisor['email']).to eq(advisor.email)
      expect(current_advisor['phone_normalized']).to eq(advisor.phone_normalized)

      # auth_token is re-generated on sign_in
      expect(current_advisor['authentication_token']).not_to eq(advisor.authentication_token)
    end

    it 'should successfuly set last logged in web app' do
      xhr :post, :create, session: valid_sign_in_params
      expect(response).to have_http_status(200)

      user_statistic = advisor.user_statistic
      expect(user_statistic.last_logged_in_web_app).not_to eq(nil)
    end

    it 'should return error when params are invalid' do
      xhr :post, :create, session: invalid_sign_in_params
      expect(response).to have_http_status(401)

      error = JSON.parse(response.body)
      expect(error['message']).to eq('Invalid email.')
    end

  end

  context 'destroy' do

    it 'should successfuly sign_out when auth_token is valid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :delete, :destroy
      expect(response).to have_http_status(204)

      advisor.reload
      expect(advisor.authentication_token).to eq(nil) # auth_token is deleted on sign_out
    end

    it 'should return error when params are invalid' do
      request.headers['X-USER-TOKEN'] = Devise.friendly_token # some random token
      xhr :delete, :destroy
      expect(response).to have_http_status(401)

      error = JSON.parse(response.body)
      expect(error['error_message']).to eq("Invalid authentication_token.")
    end

  end
end
