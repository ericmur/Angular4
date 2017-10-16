require 'rails_helper'

describe Messagable::MessageUser, type: :model do

  context 'Associations' do
    it { is_expected.to belong_to(:receiver) }
    it { is_expected.to belong_to(:message) }
  end

end
