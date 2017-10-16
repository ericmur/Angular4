require 'rails_helper'

RSpec.describe WorkflowStandardDocument, type: :model do
  context 'associations' do
    it { is_expected.to belong_to(:ownerable) }
    it { is_expected.to belong_to(:standard_document) }
    it { is_expected.to have_many(:workflow_document_uploads).dependent(:destroy) }
  end

  context 'validations' do
    it { is_expected.to validate_uniqueness_of(:standard_document_id).scoped_to([:ownerable_id, :ownerable_type]).case_insensitive }
  end
end
