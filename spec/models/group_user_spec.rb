require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe GroupUser, :type => :model do
  before(:each) do
    load_standard_documents
    load_docyt_support
  end

  let!(:group) { create(:group, owner: create(:consumer)) }

  it 'should not create 2 users with same email' do
    group_user1 = FactoryGirl.create(:group_user, :email => 'shilpa@vayuum.com', :phone => '4134567890', :user => nil, :group => group)
    expect {
      group_user2 = FactoryGirl.create(:group_user, :email => 'shilpa@vayuum.com', :phone => '4137891230', :user => nil, :group => group)
    }.to raise_error(ActiveRecord::RecordInvalid, /Email has already been associated with another member in your Contacts/)
  end

  it 'should not create 2 users with same phone' do
    group_user1 = FactoryGirl.create(:group_user, :email => 'shilpa2@vayuum.com', :phone => '4134567890', :user => nil, :group => group)
    expect {
      group_user2 = FactoryGirl.create(:group_user, :email => 'shilpa1@vayuum.com', :phone => '4134567890', :user => nil, :group => group)
    }.to raise_error(ActiveRecord::RecordInvalid, /Phone has already been associated with another member in your Contacts/)
  end

  it 'should not add same user to the group twice' do
    user = FactoryGirl.create(:consumer)
    group_user1 = FactoryGirl.create(:group_user, :email => nil, :phone => nil, :user => user, :group => group)
    expect {
      group_user2 = FactoryGirl.create(:group_user, :email => nil, :phone => nil, :user => user, :group => group)
    }.to raise_error(ActiveRecord::RecordInvalid, /User can only be .* once/)
  end

  it 'should not allow creating a user with nil name' do
    expect {
      group_user1 = FactoryGirl.create(:group_user, :name => nil, :email => 'shilpa2@vayuum.com', :phone => '4134567890', :user => nil, :group => group)
    }.to raise_error(ActiveRecord::RecordInvalid, /Name can't be blank/)
  end

  it 'should allow for blank phone and email' do
    group_user1 = FactoryGirl.create(:group_user, :name => 'Shilpa Dhir', :email => nil, :phone => nil, :user => nil, :group => group)

  end

  it 'should not allow adding a user to a nil group' do
    expect {
      group_user1 = FactoryGirl.create(:group_user, :name => nil, :email => 'shilpa2@vayuum.com', :phone => '4134567890', :user => nil, :group => nil)
    }.to raise_error
  end

  it 'should clear phone/email/name once user_id is registered' do
    group_user1 = FactoryGirl.create(:group_user, :email => 'shilpa@vayuum.com', :phone => '4134567890', :user => nil, :group => group)
    user = FactoryGirl.create(:user)
    expect(group_user1.name).not_to eq(nil)
    expect(group_user1.phone).not_to eq(nil)
    expect(group_user1.email).not_to eq(nil)

    group_user1.user_id = user.id
    group_user1.save!

    expect(group_user1.name).to eq(nil)
    expect(group_user1.phone).to eq(nil)
    expect(group_user1.email).to eq(nil)
  end

end
