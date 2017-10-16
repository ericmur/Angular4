require 'rails_helper'
require 'custom_spec_helper'

describe Api::Web::V1::ConsumerAccountTypesController do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:advisor)  { create(:advisor) }

  context '#index' do
    it 'should return all consumer account types' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index
      expect(response).to have_http_status(200)

      result = JSON.parse(response.body)['consumer_account_types']
      expect(result.size).to eq(ConsumerAccountType.count)
    end
  end
end
