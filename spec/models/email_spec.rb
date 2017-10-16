require 'rails_helper'

RSpec.describe Email, type: :model do
  it { expect validate_presence_of(:from_address) }
  it { expect validate_presence_of(:to_addresses) }

  it 'has a valid factory' do
    expect(FactoryGirl.create(:email)).to be_valid
  end
end
