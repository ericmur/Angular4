require 'rails_helper'

RSpec.describe WorkflowDocumentUpload, type: :model do
  context 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:document) }
    it { is_expected.to belong_to(:workflow_standard_document) }
  end

  context 'validations' do
    it { is_expected.to validate_presence_of(:user_id) }
    it { is_expected.to validate_presence_of(:document_id) }
    it { is_expected.to validate_presence_of(:workflow_standard_document_id) }
  end
end
