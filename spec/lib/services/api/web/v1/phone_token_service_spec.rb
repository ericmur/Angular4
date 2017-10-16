require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::PhoneTokenService do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:service) { Api::Web::V1::PhoneTokenService }

  let!(:advisor) { build(:advisor, phone_confirmed_at: nil) }

  let(:web_token)   { advisor.web_phone_confirmation_token }
  let(:phone_token) { advisor.phone_confirmation_token }

  let!(:invalid_token) { Faker::Number.number(5) }

  context '#set_confirmation_token' do
    before do
      advisor.save
    end

    it 'should update web_phone_confirmed_at and web_phone_confirmation_token fields of advisor' do
      advisor.send_phone_token(type: 'web')

      expect(advisor.web_phone_confirmed_at).to be_nil
      expect(advisor.web_phone_confirmation_token).to_not be_nil

      service.new(advisor, advisor: { type: 'web', token: web_token }).set_confirmation_token
      advisor.reload

      expect(advisor.web_phone_confirmed_at).to_not be_nil
      expect(advisor.web_phone_confirmation_token).to be_nil
    end

    it 'should not update web_phone_confirmed_at and web_phone_confirmation_token fields of advisor if token invalid' do
      advisor.send_phone_token(type: 'web')

      expect(advisor.web_phone_confirmed_at).to be_nil
      expect(advisor.web_phone_confirmation_token).to_not be_nil

      service_token = service.new(advisor, advisor: { type: 'web', token: invalid_token })
      service_token.set_confirmation_token
      advisor.reload

      expect(service_token.get_errors.include?("Invalid Code. Please try again.")).to be_truthy

      expect(advisor.web_phone_confirmed_at).to be_nil
      expect(advisor.web_phone_confirmation_token).to eq(web_token)
    end

    it 'should update phone_confirmed_at and phone_confirmation_token fileds of advisor' do
      advisor.send_phone_token

      expect(advisor.phone_confirmed_at).to be_nil
      expect(advisor.phone_confirmation_token).to_not be_nil

      service.new(advisor, advisor: { token: phone_token }).set_confirmation_token
      advisor.reload

      expect(advisor.phone_confirmed_at).to_not be_nil
      expect(advisor.phone_confirmation_token).to be_nil
    end

    it 'should not update phone_confirmed_at and phone_confirmation_token fields of advisor if token invalid' do
      advisor.send_phone_token

      expect(advisor.phone_confirmed_at).to be_nil
      expect(advisor.phone_confirmation_token).to_not be_nil

      service_token = service.new(advisor, advisor: { token: invalid_token })
      service_token.set_confirmation_token
      advisor.reload

      expect(service_token.get_errors.include?("Invalid Code. Please try again.")).to be_truthy

      expect(advisor.phone_confirmed_at).to be_nil
      expect(advisor.phone_confirmation_token).to eq(phone_token)
    end

    it 'should update set verified phone number of advisor' do
      phone = FactoryGirl.generate(:phone)
      token = Faker::Number.number(5)

      advisor.update(unverified_phone: phone, phone_confirmation_token: token)

      expect(advisor.phone_confirmed_at).to be_nil

      service.new(advisor, advisor: { change_phone_number: true, token: token }).set_confirmation_token
      advisor.reload

      expect(advisor.phone).to eq(phone)
      expect(advisor.unverified_phone).to be_nil
      expect(advisor.phone_confirmed_at).to_not be_nil
      expect(advisor.phone_confirmation_token).to be_nil
    end
  end

  context '#send_phone_token' do
    let!(:advisor_web)    { create(:advisor) }
    let!(:advisor_iphone) { create(:advisor_iphone) }

    it 'should call to #resend_phone_token for web type if advisor not have setup web app' do
      expect_any_instance_of(User).to receive(:resend_phone_confirmation_code).with(type: 'web').and_call_original
      expect_any_instance_of(TokenUtils).to receive(:send_token)
        .with(
          confirmation_token_field: :web_phone_confirmation_token,
          phone: advisor_iphone.phone_normalized,
          message: User::PHONE_CONFIRM_MESSAGE
        ).and_call_original

      service.new(advisor_iphone, resend_code: true).send_phone_token
    end

    it 'should call to #resend_phone_token without web type if advisor have setup web app' do
      expect_any_instance_of(User).to receive(:resend_phone_confirmation_code).and_call_original
      expect_any_instance_of(TokenUtils).to receive(:send_token)
        .with(
          confirmation_token_field: :phone_confirmation_token,
          phone: advisor_web.phone_normalized,
          message: User::PHONE_CONFIRM_MESSAGE
        ).and_call_original

      service.new(advisor_web, resend_code: true).send_phone_token
    end

    it 'should call to #send_phone_token for web type if advisor not have setup web app' do
      expect_any_instance_of(User).to receive(:send_phone_token).with(type: 'web').and_call_original
      expect_any_instance_of(TokenUtils).to receive(:generate_and_send_token)
        .with(
          confirmation_token_field:   :web_phone_confirmation_token,
          confirmation_sent_at_field: :web_phone_confirmation_sent_at,
          phone: advisor_iphone.phone_normalized,
          message: User::PHONE_CONFIRM_MESSAGE
        ).and_call_original

      service.new(advisor_iphone, {}).send_phone_token
    end

    it 'should call to #send_phone_token without web type if advisor have setup web app' do
      expect_any_instance_of(User).to receive(:send_phone_token).and_call_original
      expect_any_instance_of(TokenUtils).to receive(:generate_and_send_token)
        .with(
          confirmation_token_field:   :phone_confirmation_token,
          confirmation_sent_at_field: :phone_confirmation_sent_at,
          phone: advisor_web.phone_normalized,
          message: User::PHONE_CONFIRM_MESSAGE
        ).and_call_original

      service.new(advisor_web, {}).send_phone_token
    end
  end
end
