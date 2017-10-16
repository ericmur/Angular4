require 'rails_helper'
require 'custom_spec_helper'

describe Api::Web::V1::AdvisorsController do
  before(:each) do
    load_standard_documents
    load_docyt_support
  end

  let!(:advisor) { create(:advisor) }

  context 'create' do
    let!(:password) { Faker::Lorem.characters(8) }
    let!(:short_password) { Faker::Lorem.characters(4) }

    let(:valid_create_params) {
      std_category = StandardCategory.first
      {
        'app_type' => User::WEB_APP,
        'email' => Faker::Internet.email,
        'password' => password,
        'password_confirmation' => password,
        'standard_category_id' => std_category.id
      }
    }

    let(:invalid_create_params) {
      {
        'email' => "@#{Faker::Internet.email}@",
        'password' => short_password,
        'password_confirmation' => short_password
      }
    }

    it 'should create an advisor when params are valid' do
      expect {
        xhr :post, :create, advisor: valid_create_params
      }.to change(User, :count).by(1)
      expect(response).to have_http_status(201)
    end

    it 'should not create an advisor when params are invalid' do
      expect {
        xhr :post, :create, advisor: invalid_create_params
      }.not_to change(User, :count)
      expect(response).to have_http_status(422)

      errors = JSON.parse(response.body)

      expect(errors).to include('email')
      expect(errors).to include('password')
    end
  end

  context 'update' do
    before do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

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

    let(:valid_update_params) {
      {
        'id' => advisor.id,
        'first_name' => Faker::Name.first_name,
        'middle_name' => "",
        'last_name' => Faker::Name.last_name,
        'email' => Faker::Internet.email,
        'current_password' => current_password,
        'password' => new_password,
        'password_confirmation' => new_password
      }
    }

    let(:invalid_update_params) {
      {
        'id' => advisor.id,
        'unverified_email' => "@#{Faker::Internet.email}@",
        'current_password' => new_password,
        'password' => short_password
      }
    }
    before do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    it 'should update an advisor when params are valid' do
      xhr :put, :update, { id: advisor.id, advisor: valid_update_params }

      expect(response).to have_http_status(200)
    end

    it 'should not update advisor when params are invalid' do
      xhr :put, :update, { id: advisor.id, advisor: invalid_update_params }

      errors = JSON.parse(response.body)

      expect(response).to have_http_status(422)
      expect(errors.keys).to include('unverified_email')
      expect(errors.keys).to include('password')
    end
  end

  context 'get_current_advisor' do
    it 'should return advisor when auth_token valid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :get_current_advisor
      expect(response).to have_http_status(200)

      current_advisor = JSON.parse(response.body)['advisor']
      expect(current_advisor['email']).to eq(advisor.email)
      expect(current_advisor['authentication_token']).to eq(advisor.authentication_token)
      expect(current_advisor['phone_normalized']).to eq(advisor.phone_normalized)
    end

    it 'should return error when auth_token invalid' do
      request.headers['X-USER-TOKEN'] = Devise.friendly_token # some random token
      xhr :get, :get_current_advisor
      expect(response).to have_http_status(401)

      error = JSON.parse(response.body)
      expect(error['error_message']).to eq("Invalid authentication_token.")
    end
  end

  context 'add_phone_number' do
    before do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    let!(:valid_phone_number) { generate(:phone) }
    let!(:invalid_phone_number) { '911' }
    let!(:normalized_phone) { PhonyRails.normalize_number(valid_phone_number, :country_code => 'US')}
    let(:valid_phone_params){
      {
        'phone' => valid_phone_number
      }
    }
    let(:invalid_phone_params){
      {
        'phone' => invalid_phone_number
      }
    }

    before do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    it 'should create advisor phone number when params valid' do
      xhr :post, :add_phone_number, valid_phone_params
      expect(response).to have_http_status(200)

      current_advisor = JSON.parse(response.body)['advisor']
      expect(current_advisor['phone_normalized']).to eq(normalized_phone)
    end

    it 'should return error when phone is invalid' do
      xhr :post, :add_phone_number, invalid_phone_params
      expect(response).to have_http_status(406)

      error = JSON.parse(response.body)
      expect(error['error_message']['phone']).to include('is an invalid number')
    end
  end

  context '#confirm_phone_number' do
    let(:phone_token)     { advisor.phone_confirmation_token }
    let(:web_phone_token) { advisor.web_phone_confirmation_token }

    before do
      allow_any_instance_of(User).to receive(:password_private_key).and_return(false)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    it 'should return status 200 and update web phone token if token is valid' do
      advisor.send_phone_token(type: 'web')

      xhr :put, :confirm_phone_number, advisor: { type: 'web', token: web_phone_token }
      expect(response).to have_http_status(200)

      advisor.reload

      expect(advisor.web_phone_confirmed_at).to_not be_nil
      expect(advisor.web_phone_confirmation_token).to be_nil
    end

    it 'should confirm phone number when confirmation token is valid' do
      advisor.send_phone_token

      xhr :put, :confirm_phone_number, advisor: { token: phone_token }
      expect(response).to have_http_status(200)

      advisor.reload
      expect(advisor.phone_confirmed_at).not_to be(nil)
      expect(advisor.phone_confirmation_token).to be(nil)
    end

    it 'should return status 406 if confirmation token is invalid' do
      xhr :put, :confirm_phone_number, advisor: { token: Faker::Number.number(5) }
      expect(response).to have_http_status(406)
    end

    it 'should return status 406 if web token is incorrect' do
      xhr :put, :confirm_phone_number, advisor: { type: 'web', token: Faker::Number.number(5) }
      expect(response).to have_http_status(406)
    end
  end

  context '#get_advisor_types' do
    it 'should return advisor types without docyt support id' do
      xhr :post, :get_advisor_types
      expect(response).to have_http_status(200)

      result = JSON.parse(response.body)
      standard_category_ids = result["standard_categories"].map { |advisor| advisor['id']}

      expect(standard_category_ids.include?(StandardCategory::DOCYT_SUPPORT_ID)).to be_falsey
    end
  end

  context '#search' do
    let!(:advisor) { create(:advisor) }

    it 'should return 200 if user is found' do
      xhr :get, :search, search: { phone: advisor.phone }
      expect(response).to have_http_status(200)
    end

    it 'should return 404 if user is not found' do
      xhr :get, :search, search: { phone: Faker::PhoneNumber.cell_phone }
      expect(response).to have_http_status(404)
    end
  end

  context '#confirm_pincode' do
    let!(:advisor) { create(:advisor) }
    let!(:pincode) { Faker::Number.number(5) }
    let!(:phone)   { advisor.phone }

    before do
      allow_any_instance_of(User).to receive(:password_private_key).and_return(false)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    it 'should return status 200 if pincode is valid and advisor do not have password_private_key' do
      allow_any_instance_of(User).to receive(:valid_pin?).and_return(true)

      xhr :put, :confirm_pincode, advisor: { id: advisor.id, phone: phone, pincode: pincode }
      expect(response).to have_http_status(200)

      pin_status = JSON.parse(response.body)['pincode_status']
      expect(pin_status['valid_pin']).to be_truthy
    end

    it 'should return status 406 if pincode is incorrect' do
      allow_any_instance_of(User).to receive(:valid_pin?).and_return(false)
      xhr :put, :confirm_pincode, advisor: { id: advisor.id, phone: phone, pincode: pincode }
      expect(response).to have_http_status(406)
    end
  end

  context '#confirm_credentials' do
    let!(:advisor) { create(:advisor) }
    let!(:pincode) { Faker::Number.number(5) }
    let!(:phone)   { advisor.phone }

    let!(:unverified_email) { Faker::Internet.email }

    let!(:password)         { Faker::Lorem.characters(8) }
    let!(:short_password)   { Faker::Number.number(4) }

    let!(:valid_params) {
      {
        id: advisor.id,
        phone: phone,
        pincode: pincode,
        password: password,
        password_confirmation: password
      }
    }

    let!(:invalid_params) {
      {
        phone: phone,
        pincode: pincode,
        password: short_password,
        password_confirmation: short_password
      }
    }

    before do
      allow_any_instance_of(User).to receive(:password_private_key).and_return(false)
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
    end

    it 'should return status 200 and successfully message if email is changed' do
      expect(advisor.unverified_email).to be_nil
      expect(advisor.valid_password?(password)).to be_falsey

      xhr :put, :confirm_credentials, advisor: valid_params.merge(unverified_email: unverified_email)
      expect(response).to have_http_status(200)

      advisor.reload
      expect(advisor.unverified_email).to eq(unverified_email)
      expect(advisor.valid_password?(password)).to be_truthy

      success = JSON.parse(response.body)
      expect(success['message']).to eq('Sign In with the account you have just setup')
    end

    it 'should return status 200 and successfully message if email is not changed' do
      expect(advisor.unverified_email).to be_nil
      expect(advisor.valid_password?(password)).to be_falsey

      xhr :put, :confirm_credentials, advisor: valid_params
      expect(response).to have_http_status(200)

      advisor.reload
      expect(advisor.unverified_email).to_not eq(unverified_email)
      expect(advisor.valid_password?(password)).to be_truthy

      success = JSON.parse(response.body)
      expect(success['message']).to eq('Sign In with the account you have just setup')
    end

    it 'should return status 422 if form not be saved' do
      xhr :put, :confirm_credentials, advisor: invalid_params.merge(unverified_email: "@#{unverified_email}@")
      expect(response).to have_http_status(422)

      errors = JSON.parse(response.body)

      expect(errors).to include('password')
      expect(errors).to include('unverified_email')
    end

  end

  context 'resend_email_confirmation' do
    it 'should resend email confirmation to advisor' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      allow(UserMailer).to receive_message_chain("email_confirmation.deliver_later") { true }
      advisor.update(email_confirmed_at: Time.current)

      expect(UserMailer).to receive(:email_confirmation).with(advisor.id, advisor.email_confirmation_token.to_s)
      xhr :get, :resend_email_confirmation

      advisor.reload
      expect(advisor.email_confirmed_at).to be_nil
    end
  end

  context '#send_phone_token' do
    it 'should call to PhoneTokenService' do
      expect(Api::Web::V1::PhoneTokenService).to receive(:new).and_call_original
      expect_any_instance_of(Api::Web::V1::PhoneTokenService).to receive(:send_phone_token).and_call_original


      xhr :get, :send_phone_token, user_id: advisor.id
      expect(response).to have_http_status(200)
    end
  end

end
