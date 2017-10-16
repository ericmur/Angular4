require 'rails_helper'

RSpec.describe Participant, type: :model do
  context 'Associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:workflow) }
    it { is_expected.to have_many(:workflow_standard_documents) }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:user_id) }
  end
end
