require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Web::V1::ClientsController do
  before do
    stub_request(:post, /.twilio.com/).to_return(status: 200)
    allow(TwilioClient).to receive_message_chain("get_instance.account.messages.create") { true }
    load_standard_documents
    load_docyt_support
  end

  let!(:advisor)  { create(:advisor) }
  let!(:client)   { create(:client, advisor: advisor) }

  let!(:another_advisor)  { create(:advisor) }

  context 'index' do
    it 'should return list for advisor with clients' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index
      clients_list = JSON.parse(response.body)['clients']

      expect(clients_list.count).to eq(1)
      expect(response).to have_http_status(200)
    end

    it 'should return empty clients list for advisor' do
      request.headers['X-USER-TOKEN'] = another_advisor.authentication_token
      xhr :get, :index
      clients_list = JSON.parse(response.body)['clients']

      expect(clients_list.count).to eq(0)
      expect(response).to have_http_status(200)
    end
  end

  context 'show' do
    it 'should return client if current_advisor has this client' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :show, id: client.id
      client_json = JSON.parse(response.body)['client']

      expect(client_json['id']).to eq(client.id)
      expect(response).to have_http_status(200)
    end

    it 'should not return client if current_advisor has no such client' do
      request.headers['X-USER-TOKEN'] = another_advisor.authentication_token
      xhr :get, :show, id: Faker::Number.number(3)
      response_body = JSON.parse(response.body)

      expect(response_body).to eq({})
      expect(response).to have_http_status(404)
    end
  end

  context 'create' do
    let!(:business_partner)  { create(:business_partner, user: advisor) }

    let!(:valid_client_params) {
      {
        'email' => Faker::Internet.email,
        'name'  => Faker::Name.name,
        'phone' => FactoryGirl.generate(:phone)
      }
    }

    let!(:valid_invitation_params) {
      {
        'email' => valid_client_params['email'],
        'phone' => valid_client_params['phone'],
        'email_invitation' => true,
        'text_invitation' => true
      }
    }

    let!(:invalid_client_params) {
      {
        'email' => '',
        'name'  => '',
        'phone' => FactoryGirl.generate(:phone)+'0000'
      }
    }

    let!(:invalid_invitation_params) {
      {
        'email' => '',
        'phone' => ''
      }
    }

    it 'should create and return a client when params valid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        xhr :post, :create, client: valid_client_params
      }.to change(Client, :count).by(1)

      client = JSON.parse(response.body)['client']

      expect(client['parsed_fullname']).to eq(valid_client_params['name'])
      expect(client['email']).to eq(valid_client_params['email'])
      expect(client['phone']).to eq(valid_client_params['phone'])
      expect(response).to have_http_status(201)
    end

    it 'should create and return a client and invitation for him when params valid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      valid_client_params['invitation'] = valid_invitation_params

      expect {
        xhr :post, :create, client: valid_client_params
      }.to change(Invitationable::Invitation, :count).by(1)

      client = JSON.parse(response.body)['client']

      expect(client['parsed_fullname']).to eq(valid_client_params['name'])
      expect(client['email']).to eq(valid_client_params['email'])
      expect(client['phone']).to eq(valid_client_params['phone'])
      expect(response).to have_http_status(201)
    end

    it 'should return client errors when client params invalid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token

      expect {
        xhr :post, :create, client: invalid_client_params
      }.not_to change(Client, :count)

      errors = JSON.parse(response.body)

      expect(errors['client_errors']).to include("Name can't be blank")
      expect(errors['client_errors']).to include("Phone is an invalid number")
      expect(response).to have_http_status(422)
    end

    it 'should return invitation errors when invitation params invalid' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      invalid_client_params['invitation'] = invalid_invitation_params
      advisor.update(first_name: nil, last_name: nil)

      expect {
        xhr :post, :create, client: invalid_client_params
      }.not_to change(Invitationable::Invitation, :count)

      errors = JSON.parse(response.body)

      expect(errors['invitation_errors']).to include(I18n.t('errors.invitation.require_fullname'))
      expect(errors['invitation_errors']).to include("Phone can't be blank")
      expect(errors['invitation_errors']).to include("Email can't be blank")
      expect(response).to have_http_status(422)
    end
  end

  context '#search' do
    it 'should return list for advisor with find clients' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :search, fulltext_search: client.owner_name
      clients_list = JSON.parse(response.body)['clients']

      expect(clients_list.count).to eq(1)
      expect(response).to have_http_status(200)
    end

    it 'should return empty clients list for advisor' do
      request.headers['X-USER-TOKEN'] = another_advisor.authentication_token
      xhr :get, :search, fulltext_search: client.owner_name
      clients_list = JSON.parse(response.body)['clients']

      expect(clients_list.count).to eq(0)
      expect(response).to have_http_status(200)
    end
  end

end
