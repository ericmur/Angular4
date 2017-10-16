require 'rails_helper'

RSpec.describe Group, type: :model do
  context 'Associations' do
    it { is_expected.to have_many(:group_users) }
    it { is_expected.to belong_to(:standard_group) }
    it { is_expected.to belong_to(:owner).class_name(User.name.to_s) }
  end

  context 'Validations' do
    subject { Group.new(standard_group_id: Faker::Number.number(3)) }

    it { is_expected.to validate_presence_of(:standard_group_id) }
    it { is_expected.to validate_uniqueness_of(:owner_id).scoped_to(:standard_group_id).case_insensitive }
  end
end
