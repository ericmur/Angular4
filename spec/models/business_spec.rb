require 'rails_helper'

RSpec.describe Business, type: :model do
  context 'Associations' do
    it { is_expected.to have_many(:business_partners).dependent(:destroy) }
    it { is_expected.to have_many(:business_documents).dependent(:destroy) }
  end

  context 'Validations' do
    it { expect(subject).to validate_presence_of(:name) }
  end
end
