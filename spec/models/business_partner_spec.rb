require 'rails_helper'

RSpec.describe BusinessPartner, type: :model do
  context 'Associations' do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:user) }
  end
end
