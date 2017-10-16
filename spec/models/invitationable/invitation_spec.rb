require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'
require 's3'

RSpec.describe Invitationable::Invitation, type: :model do
  context "Associations" do
    it { is_expected.to belong_to(:accepted_by_user).class_name("User") }
    it { is_expected.to belong_to(:created_by_user).class_name("User") }
    it { is_expected.to belong_to(:rejected_by_user).class_name("User") }
  end
end
