require 'rails_helper'

RSpec.describe UserCreditTransaction, type: :model do
  context 'Associations' do
    it { is_expected.to belong_to(:user_credit).class_name(UserCredit.name.to_s) }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:fax_balance) }
  end
end
