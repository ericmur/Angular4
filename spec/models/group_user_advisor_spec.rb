require 'rails_helper'

RSpec.describe GroupUserAdvisor, type: :model do
  context 'Associations' do
    it { is_expected.to belong_to(:advisor) }
    it { is_expected.to belong_to(:group_user) }
  end
end
