require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::ContactsQuery do
  before do
    load_standard_documents
    load_docyt_support

    create(:connected_group_user, group: group, label: Faker::Company.profession, advisors: [advisor])
    create(:unconnected_group_user, group: group, label: Faker::Company.profession, advisors: [advisor])

    create(:connected_group_user, group: another_group, label: Faker::Company.profession, advisors: [advisor])
    create(:unconnected_group_user, group: another_group, label: Faker::Company.profession, advisors: [advisor])
  end

  let!(:standard_group) { create(:standard_group) }

  let!(:advisor)        { create(:advisor) }
  let!(:another_client) { create(:client, :connected, advisor: advisor) }

  let!(:business_consumer)     { create(:consumer, consumer_account_type_id: ConsumerAccountType::BUSINESS) }
  let!(:not_bisuness_consumer) { create(:consumer, consumer_account_type_id: ConsumerAccountType::INDIVIDUAL) }

  let!(:business_client) { create(:client, consumer: business_consumer, advisor: advisor) }
  let!(:group)           { create(:group, standard_group: standard_group, owner: business_client.consumer) }

  let!(:not_bisuness_client) { create(:client, consumer: not_bisuness_consumer, advisor: advisor) }
  let!(:another_group)       { create(:group, standard_group: standard_group, owner: not_bisuness_client.consumer) }

  let!(:query) { Api::Web::V1::ContactsQuery }

  context '#get_contacts' do
    it 'should call to #get_label_contacts' do
      expect_any_instance_of(query).to receive(:get_label_contacts).and_return(GroupUser.all)
      query.new(advisor, { group_label: GroupUser::CONTRACTOR }).get_contacts
    end

    it 'should call to #get_contacts_for_client' do
      expect_any_instance_of(query).to receive(:get_contacts_for_user).and_return(GroupUser.all)
      query.new(advisor, {}).get_contacts
    end

    it 'should call to #get_contacts_for_group_owner' do
      expect_any_instance_of(query).to receive(:get_contacts_for_group_owner).and_return(GroupUser.all)
      query.new(advisor, { user_id: Faker::Number.number(2) }).get_contacts
    end
  end

  context '#get_label_contacts' do
    it 'should return group users with label Contractor' do
      contractor = create(:connected_group_user, group: group, label: GroupUser::CONTRACTOR, advisors: [advisor])

      group_users = query.new(advisor, { group_label: GroupUser::CONTRACTOR, client_id: business_client.id }).get_label_contacts

      expect(group_users.count).to eq(1)
      expect(group_users.ids).to include(contractor.id)
      expect(group_users.first.label).to eq(GroupUser::CONTRACTOR)
    end

    it 'should return group users with label Employee' do
      employee = create(:connected_group_user, group: group, label: GroupUser::EMPLOYEE, advisors: [advisor])

      group_users = query.new(advisor, { group_label: GroupUser::EMPLOYEE, client_id: business_client.id }).get_label_contacts

      expect(group_users.count).to eq(1)
      expect(group_users.ids).to include(employee.id)
      expect(group_users.first.label).to eq(GroupUser::EMPLOYEE)
    end

    it 'should return group users where != Employee or Contractor' do
      group_users = query.new(advisor, { group_label: Faker::Company.profession, client_id: business_client.id }).get_label_contacts

      expect(group_users.count).to eq(2)
      expect(group_users.sample.label).not_to eq(GroupUser::EMPLOYEE)
      expect(group_users.sample.label).not_to eq(GroupUser::CONTRACTOR)
    end

    it 'should return empty list if the client is not shared contacts' do
      group_users = query.new(advisor, { group_label: Faker::Company.profession, client_id: another_client.id }).get_label_contacts

      expect(group_users).to be_empty
    end
  end

  context '#get_contacts_for_user' do
    it 'should return group users including label Employee and Contractor if client.consumer have Business type' do
      employee = create(:connected_group_user, group: group, label: GroupUser::EMPLOYEE, advisors: [advisor])
      contractor = create(:connected_group_user, group: group, label: GroupUser::CONTRACTOR, advisors: [advisor])

      group_users = query.new(advisor, { client_id: business_client.id }).get_contacts_for_user

      expect(group_users.count).to eq(4)
      expect(group_users.ids).to include(employee.id)
      expect(group_users.ids).to include(contractor.id)
    end

    it 'should return group users without label Employee and Contractor if client.consumer don`t have Business type' do
      employee = create(:connected_group_user, group: another_group, label: GroupUser::EMPLOYEE, advisors: [advisor])
      contractor = create(:connected_group_user, group: another_group, label: GroupUser::CONTRACTOR, advisors: [advisor])

      group_users = query.new(advisor, { client_id: not_bisuness_client.id }).get_contacts_for_user

      expect(group_users.count).to eq(2)
      expect(group_users.ids).not_to include(employee.id)
      expect(group_users.ids).not_to include(contractor.id)
    end

    it 'should return empty list of group users if don`t have shared contacts' do
      group_users = query.new(advisor, { group_label: Faker::Company.profession, client_id: another_client.id }).get_contacts_for_user

      expect(group_users).to be_empty
    end
  end

  context '#get_contacts_for_group_owner' do
    it 'should get all contacts when user is group owner' do
      group_users = query.new(advisor, { user_id: business_client.consumer.id }).get_contacts_for_group_owner
      group_users_of_group_owner = business_client.consumer.group_users_as_group_owner

      expect(group_users.size).to eq(2)
      expect(group_users.ids).to eq(group_users_of_group_owner.ids)
      expect(group_users.size).to eq(group_users_of_group_owner.size)
    end

    it 'should return empty relation if user not found' do
      group_users = query.new(advisor, { user_id: Faker::Number.number(3) }).get_contacts_for_group_owner

      expect(group_users).to be_empty
    end
  end

  context '#get_contact' do
    it 'should return client' do
      client = query.new(advisor, { contact_type: Client.name.to_s, id: another_client.id }).get_contact

      expect(client.class.name).to eq(Client.name.to_s)
    end

    it 'should return group user' do
      group_user = query.new(advisor, { contact_type: GroupUser.name.to_s, id: GroupUser.first.id }).get_contact

      expect(group_user.class.name).to eq(GroupUser.name.to_s)
    end
  end
end
