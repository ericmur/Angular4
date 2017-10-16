require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Page do
  before(:each) do
    stub_request(:any, /.*twilio.com.*/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain('get_instance.account.messages.create')
    stub_docyt_support_creation
  end
  describe 'Callbacks' do
    it { is_expected.to callback(:delete_s3_object).after(:destroy) }
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:document) }
    it { is_expected.to have_many(:locations).dependent(:destroy) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:document_id) }
    it { is_expected.to validate_presence_of(:page_num) }
    it { is_expected.to validate_numericality_of(:page_num).is_greater_than(0) }

    # shoulda-matchers do not support conditional validations, so we do it ourselves:
    context 'Page state - uploaded' do
      let(:page) { create(:page) }

      before { allow_any_instance_of(Page).to receive(:uploaded?).and_return(true) }

      it { is_expected.to validate_presence_of(:original_s3_object_key) }
      it { expect(page).to validate_uniqueness_of(:original_s3_object_key) }
    end

    context 'Page state - not uploaded' do
      let(:page) { create(:page) }

      before { allow_any_instance_of(Page).to receive(:uploaded?).and_return(false) }

      it { is_expected.not_to validate_presence_of(:original_s3_object_key) }
      it { expect(page).not_to validate_uniqueness_of(:original_s3_object_key) }
    end
  end

  describe 'Methods' do
    let(:page) { create(:page) }

    context '#recreate_document_pdf' do
      it 'should enqueue pdf generation job to Resque' do
        expect(Resque).to receive(:enqueue).with(ConvertDocumentPagesToPdfJob, page.document.id)
        .and_return(true)
        page.recreate_document_pdf
      end
    end
  end

  describe 'State machine' do
    let(:page) { create(:page, state: 'pending') }

    it 'should contain all needed states' do
      page_states = Page.aasm.states_for_select.flatten
      expect(page_states).to include('pending', 'uploading', 'uploaded')
    end

    it 'should be able to go to :uploading state only from initial state' do
      expect(page).to allow_event(:start_upload)
      expect(page).to allow_transition_to(:uploading)

      expect(page).to_not allow_event(:complete_upload)
      expect(page).to_not allow_transition_to(:uploaded)

      expect(page).to_not allow_event(:reupload)
    end

    it 'should be allowed to go to :uploaded from initial state if s3 object exists' do
      allow_any_instance_of(Page).to receive(:s3_object_exists?).and_return(true)

      expect(page).to allow_event(:complete_upload)
      expect(page).to allow_transition_to(:uploaded)
    end

    it 'should be allowed to go to :uploaded from :uploading state if s3 object exists' do
      allow_any_instance_of(Page).to receive(:s3_object_exists?).and_return(true)
      page.update(state: 'uploading')

      expect(page).to allow_event(:complete_upload)
      expect(page).to allow_transition_to(:uploaded)
    end

    it 'should be allowed to go to :uploaded or :uploading from uploading' do
      page.update(state: 'uploaded')
      expect(page).to allow_event(:reupload)

      page.update(state: 'uploading')
      expect(page).to allow_event(:reupload)
    end

  end

end
