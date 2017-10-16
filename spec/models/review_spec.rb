require 'rails_helper'

RSpec.describe Review, type: :model do
  context 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of(:last_version) }
    it { is_expected.to validate_presence_of(:user_id) }
  end
end
