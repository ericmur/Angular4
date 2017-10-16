require 'rails_helper'

RSpec.describe ChatDocument, type: :model do
  context 'Associations' do
    it { is_expected.to belong_to(:chat) }
    it { is_expected.to belong_to(:message) }
    it { is_expected.to belong_to(:document) }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:chat_id) }
    it { is_expected.to validate_presence_of(:message_id) }
    it { is_expected.to validate_presence_of(:document_id) }
  end
end
