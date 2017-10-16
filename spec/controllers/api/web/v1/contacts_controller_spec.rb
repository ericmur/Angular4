require 'rails_helper'
require 'custom_spec_helper'

describe Api::Web::V1::ContactsController do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:standard_group) { create(:standard_group) }

  let!(:group)       { create(:group, standard_group: standard_group, owner: advisor) }
  let!(:advisor)     { create(:advisor) }
  let!(:group_user)  { create(:unconnected_group_user, group: group) }

  let!(:client)   { create(:client, advisor: advisor, consumer: consumer) }
  let!(:consumer) { create(:consumer) }

  let!(:another_group)         { create(:group, standard_group: standard_group, owner: consumer) }
  let!(:spouse_group_user)     { create(:unconnected_group_user, label: GroupUser::SPOUSE, group: another_group) }
  let!(:contractor_group_user) { create(:unconnected_group_user, label: GroupUser::CONTRACTOR, group: another_group) }

  context '#index' do
    before do
      create(:group_user_advisor, advisor: advisor, group_user: contractor_group_user)
      create(:group_user_advisor, advisor: advisor, group_user: spouse_group_user)
    end

    it 'should return contacts for group owner' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, user_id: advisor.id

      contacts_list = JSON.parse(response.body)['contacts']

      expect(contacts_list.count).to eq(1)
      expect(response).to have_http_status(200)
    end

    it 'should return business and family contacts for client if its business' do
      client.user.update(consumer_account_type_id: ConsumerAccountType.find_by(display_name: 'Business').id)

      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, client_id: client.id

      contacts_list = JSON.parse(response.body)['contacts']

      expect(contacts_list.size).to eq(2)
      expect([contractor_group_user.label, spouse_group_user.label]).to include(contacts_list.sample['get_label'])
    end

    it 'should return only family contacts for client if he isnt business' do
      client.user.update(consumer_account_type_id: ConsumerAccountType.find_by(display_name: 'Family').id)

      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, client_id: client.id

      random_contact = JSON.parse(response.body)['contacts'].sample

      expect(random_contact['id']).to eq(spouse_group_user.id)
      expect(random_contact['email']).to eq(spouse_group_user.email)
      expect(random_contact['get_label']).to eq(spouse_group_user.label)
    end

    it 'should return contacts with specific label' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, group_label: contractor_group_user.label, client_id: client.id

      random_contact = JSON.parse(response.body)['contacts'].sample

      expect(random_contact['id']).to eq(contractor_group_user.id)
      expect(random_contact['get_label']).to eq(contractor_group_user.label)
    end
  end

  context '#show' do
    it 'should return contact if contact is client' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :show, id: client.id, contact_type: client.class.name.to_s

      contact = JSON.parse(response.body)['contact']

      expect(contact['id']).to eq(client.id)
      expect(contact['email']).to eq(client.owner_email)
    end

    it 'should return contact if contact is group user' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :show, id: group_user.id, contact_type: group_user.class.name.to_s

      contact = JSON.parse(response.body)['contact']

      expect(contact['id']).to eq(group_user.id)
      expect(contact['email']).to eq(group_user.owner_email)
    end
  end

  context '#create' do
  end

end
