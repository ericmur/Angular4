require 'rails_helper'

RSpec.describe DocumentPreparer, type: :model do
  context 'associations' do
    it { is_expected.to belong_to(:document) }
    it { is_expected.to belong_to(:preparer).class_name(User.name.to_s) }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of(:document_id) }
    it { is_expected.to validate_presence_of(:preparer_id) }
  end
end
