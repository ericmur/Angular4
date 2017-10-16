require 'rails_helper'

RSpec.describe BusinessDocument, type: :model do
  context 'Associations' do
    it { is_expected.to belong_to(:business) }
    it { is_expected.to belong_to(:document) }
  end
end
