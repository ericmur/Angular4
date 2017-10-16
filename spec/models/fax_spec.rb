require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Fax, type: :model do
  context 'Associations' do
    it { is_expected.to belong_to(:sender).class_name(User.name.to_s) }
    it { is_expected.to belong_to(:document) }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:sender_id) }
    it { is_expected.to validate_presence_of(:fax_number) }
    it { is_expected.to validate_presence_of(:document_id) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w(ready sending sent failed)) }
  end

  context 'State machine' do
    before do
      stub_docyt_support_creation
    end

    let(:document) { build(:document, :with_uploader_and_owner) }
    let(:fax) { build(:fax, document: document) }

    it 'should contain all needed states' do
      fax_states = Fax.aasm.states_for_select.flatten
      expect(fax_states).to include('ready', 'sending', 'sent', 'failed')
    end

    it 'should be able to go to :sending state only from :ready' do
      expect(fax).to allow_event(:start_sending)
      expect(fax).to allow_transition_to(:sending)

      expect(fax).not_to allow_event(:complete_sent)
      expect(fax).not_to allow_event(:failure_sent)
    end

    it 'should be able to go to :sent state only from :sending' do
      fax.start_sending

      expect(fax).to allow_event(:complete_sent)
      expect(fax).to allow_event(:failure_sent)

      expect(fax).to allow_transition_to(:sent)
      expect(fax).to allow_transition_to(:failed)
    end

    it 'should be able to go to :failed state only from :sending' do
      fax.start_sending

      expect(fax).to allow_event(:failure_sent)
      expect(fax).to allow_transition_to(:failed)
    end

  end

end
