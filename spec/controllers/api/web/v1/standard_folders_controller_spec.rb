require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::StandardFoldersController do
  before do
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
  end

  let!(:only_category) { StandardFolder.only_category }

  let!(:advisor) { create(:advisor) }
  let!(:client)  { create(:client, advisor: advisor, consumer: consumer) }

  let!(:consumer)            { create(:consumer) }
  let!(:standard_group)      { create(:standard_group) }
  let!(:consumer_group)      { create(:group, standard_group_id: standard_group.id, owner_id: consumer.id ) }
  let!(:consumer_group_user) { create(:group_user, email: consumer.email, phone:  consumer.phone, user: consumer, group: consumer_group) }

  context "#index" do
    it "should return array of standard folder for client" do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, client_id: client.id, contact_id: client.id, contact_type: 'Client'

      standard_folders = JSON.parse(response.body)['standard_folders']

      expect(standard_folders.count).to eq(advisor.standard_category.advisor_default_folders.count)
      expect(response).to have_http_status(200)
    end

    it "should return array of standard folder for group_user" do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index, client_id: client.id, contact_id: consumer_group_user.id, contact_type: 'GroupUser'

      standard_folders = JSON.parse(response.body)['standard_folders']

      expect(standard_folders.count).to eq(advisor.standard_category.advisor_default_folders.count)
      expect(response).to have_http_status(200)
    end
  end

  context "#show" do
    it "should return standard folder" do
      first_category = only_category.first

      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :show, client_id: client.id, id: first_category.id

      standard_folder = JSON.parse(response.body)['standard_folder']

      expect(standard_folder['name']).to eq(first_category.name)
      expect(response).to have_http_status(200)
    end

    it "should return nil if nonexistent standard folder" do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :show, client_id: client.id, id: Faker::Number.number(10)

      standard_folder = JSON.parse(response.body)['standard_folder']

      expect(standard_folder).to be_nil
      expect(response).to have_http_status(200)
    end
  end

end
