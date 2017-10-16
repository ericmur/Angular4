require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe UserCredit, type: :model do
  before do
    Faker::Config.locale = 'en-US'
    stub_docyt_support_creation
  end

  context 'Associations' do
    it { is_expected.to belong_to(:user).class_name(User.name.to_s) }
    it { is_expected.to have_many(:transactions).class_name(UserCreditTransaction.name.to_s) }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:fax_credit) }
  end

  context 'Transactions' do
    it 'should add credit' do
      user = FactoryGirl.create(:user)
      user_credit = user.user_credit
      fax_page_one = FactoryGirl.create(:fax_page_one)
      user_credit.purchase_fax_credit!(fax_page_one, fax_page_one.fax_credit_value, nil, nil)
      user_credit.reload
      expect(user_credit.fax_credit).to eq(1)
    end
  end
end
