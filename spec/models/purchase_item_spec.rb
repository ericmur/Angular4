require 'rails_helper'

RSpec.describe PurchaseItem, type: :model do
  context 'Associations' do
    it { is_expected.to have_many(:transactions).class_name(UserCreditTransaction.name.to_s) }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:product_identifier) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_presence_of(:fax_credit_value) }
  end
end
