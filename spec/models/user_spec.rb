require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe User, :type => :model do
  before do
    Faker::Config.locale = 'en-US'
    stub_docyt_support_creation
  end

  context 'user_credit' do
    it 'should create user_credit when user is created' do
      user = FactoryGirl.create(:user)
      expect(user.user_credit).not_to eq(nil)
      expect(user.user_credit.fax_credit).to eq(0)
    end
  end

  context 'phone_presence' do
    it 'should create user(advisor) if phone is nil' do
      FactoryGirl.create(:advisor, phone: nil)
      another_advisor = FactoryGirl.build(:advisor, phone: nil, app_type: User::WEB_APP)
      another_advisor.save
      FactoryGirl.create(:user, phone: nil)
      another_advisor = FactoryGirl.build(:user, phone: nil)
      expect(another_advisor.save).to eq(true)
    end

    it 'should not create user(advisor) with same phone' do
      advisor = FactoryGirl.create(:user)
      another_advisor = FactoryGirl.build(:user, phone: advisor.phone)
      expect(another_advisor.save).to eq(false)
    end

    it 'should allow more than 1 user with nil phone' do
      FactoryGirl.create(:advisor, phone: nil)
      password = Faker::Internet.password

      expect {
        User.create(
          email: Faker::Internet.email,
          password: password,
          password_confirmation: password,
          phone: nil,
          app_type: User::WEB_APP
        )
      }.to change(User, :count).by(1)
    end
  end

  context 'Associations' do
    it { is_expected.to have_many(:faxes).with_foreign_key('sender_id').dependent(:destroy) }
    it { is_expected.to have_one(:user_credit).dependent(:destroy) }
    it { is_expected.to have_many(:workflows).with_foreign_key('admin_id').dependent(:destroy) }
    it { is_expected.to have_many(:workflow_document_uploads).dependent(:destroy) }
    it { is_expected.to have_many(:participants).dependent(:nullify) }
    it { is_expected.to have_many(:document_preparers).with_foreign_key('preparer_id').dependent(:destroy) }
    it { is_expected.to have_many(:business_partnerships).class_name(BusinessPartner.name.to_s).dependent(:destroy) }
  end

  context '#send_phone_token' do
    let!(:user) {
      create(:consumer,
        phone_confirmation_token: nil,
        web_phone_confirmation_token: nil
      )
    }

    it 'should send web phone token and update user fields' do
      expect(user.web_phone_confirmation_token).to be_nil
      expect(user.web_phone_confirmation_sent_at).to be_nil

      user.send_phone_token(type: 'web')

      expect(user.web_phone_confirmation_token).to_not be_nil
      expect(user.web_phone_confirmation_sent_at).to_not be_nil
    end

    it 'should send phone token and update user fields' do
      old_token = user.phone_confirmation_token
      old_sent_at_token = user.phone_confirmation_sent_at

      user.send_phone_token

      expect(user.phone_confirmation_token).to_not eq(old_token)
      expect(user.phone_confirmation_sent_at).to_not eq(old_sent_at_token)
    end
  end

  context '#update_password_encrypted_private_key' do
    let!(:user) { create(:consumer) }

    it 'should setup password private key' do
      expect(user.password_private_key).to be_nil

      user.update_password_encrypted_private_key('123456', '12345678')
      user.reload

      expect(user.password_private_key).to_not be_nil
    end
  end

  context '#confirm_phone' do
    let!(:user) { create(:consumer, phone_confirmed_at: nil) }

    it 'should update web_phone_confirmation_token and web_phone_confirmed_at fields' do
      expect(user.web_phone_confirmed_at).to be_nil

      user.confirm_phone(type: 'web')

      expect(user.web_phone_confirmed_at).to_not be_nil
      expect(user.web_phone_confirmation_token).to be_nil
    end

    it 'should update phone_confirmation_token and phone_confirmed_at fields' do
      expect(user.phone_confirmed_at).to be_nil

      user.confirm_phone

      expect(user.phone_confirmed_at).to_not be_nil
      expect(user.phone_confirmation_token).to be_nil
    end
  end

  context '#resend_phone_confirmation_code' do
    let!(:advisor_web)    { create(:advisor, phone_confirmation_token: Faker::Number.number(6)) }
    let!(:advisor_mobile) { create(:advisor_iphone, web_phone_confirmation_token: Faker::Number.number(6)) }

    it 'should call resend_phone_confirmation_code with web phone field' do
      expect_any_instance_of(TokenUtils).to receive(:send_token).with(
        confirmation_token_field: :web_phone_confirmation_token,
        phone: advisor_mobile.phone_normalized,
        message: User::PHONE_CONFIRM_MESSAGE
      )

      advisor_mobile.resend_phone_confirmation_code(type: 'web')
    end

    it 'should call resend_phone_confirmation_code with phone field' do
      expect_any_instance_of(TokenUtils).to receive(:send_token).with(
        confirmation_token_field: :phone_confirmation_token,
        phone: advisor_web.phone_normalized,
        message: User::PHONE_CONFIRM_MESSAGE
      )

      advisor_web.resend_phone_confirmation_code
    end
  end

  context '#parsed_fullname' do
    let!(:advisor) { create(:advisor) }

    it 'should return name if name exists' do
      expect(advisor.last_name).not_to  be_empty
      expect(advisor.first_name).not_to be_empty

      parsed_fullname = advisor.parsed_fullname

      expect(parsed_fullname).to eq("#{advisor.first_name} #{advisor.last_name}")
    end

    it 'should return email if name not exists' do
      advisor.update(first_name: '', last_name: '')

      expect(advisor.last_name).to  be_empty
      expect(advisor.first_name).to be_empty

      email = advisor.parsed_fullname

      expect(email).to eq(advisor.email)
    end

    it 'should return empty string if name and email not exists' do
      advisor.update(first_name: '', last_name: '', email: '')

      expect(advisor.email).to be_empty
      expect(advisor.last_name).to  be_empty
      expect(advisor.first_name).to be_empty

      result = advisor.parsed_fullname

      expect(result).to be_empty
    end
  end

  context '#current_business_name' do
    let!(:standard_category) { create(:standard_category) }

    let!(:advisor)  { create(:advisor) }
    let!(:business) { create(:business) }

    it 'should return business name if current_workspace_name to eq Business' do
      advisor.update(current_workspace_name: business.class.name.to_s, current_workspace_id: business.id)

      expect(advisor.current_business_name).to eq(business.name)
    end

    it 'should return nil if current_workspace_name not to eq Business' do
      family_type = create(:consumer_account_type)

      advisor.update(current_workspace_name: family_type.display_name.to_s, current_workspace_id: family_type.id)

      expect(advisor.current_business_name).to be_nil
    end
  end

end
