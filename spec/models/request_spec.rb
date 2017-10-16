require 'rails_helper'

RSpec.describe Request, type: :model do
  context 'associations' do
    it { is_expected.to belong_to(:workflow) }
    it { is_expected.to belong_to(:requestionable) }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of(:requestionable_type) }
    it { is_expected.to validate_presence_of(:requestionable_id) }
  end
end
