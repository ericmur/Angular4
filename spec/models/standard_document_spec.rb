require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe StandardDocument, type: :model do
  before do
    stub_docyt_support_creation
  end

  context 'associations' do
    it { is_expected.to belong_to(:dimension) }
    it { is_expected.to have_one(:first_time_standard_document).dependent(:destroy) }
    it { is_expected.to have_many(:documents).with_foreign_key('standard_document_id') }
    xit { is_expected.to have_many(:suggested_documents).with_foreign_key('suggested_standard_document_id') }
    it { is_expected.to have_many(:standard_document_fields).dependent(:destroy).class_name('BaseDocumentField') }
    it { is_expected.to have_many(:default_favorites).dependent(:destroy) }
    it { is_expected.to have_many(:aliases).dependent(:destroy) }
  end

  context '#document_uploaders' do
    let!(:document) { create(:document, :with_standard_document) }
    let!(:user)     { document.uploader }
    let!(:category) { document.standard_document }

    let!(:another_user) { create(:consumer) }

    it 'should return users which uploaded documents in category' do
      document_uploaders = category.document_uploaders

      expect(document_uploaders.size).to eq(1)
      expect(document_uploaders.first.id).to eq(user.id)
    end
  end
end
