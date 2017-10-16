require 'rails_helper'
require 'custom_spec_helper'

describe Api::Web::V1::StandardGroupsController do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:advisor)  { create(:advisor) }

  context '#index' do
    it 'should return all standard groups' do
      request.headers['X-USER-TOKEN'] = advisor.authentication_token
      xhr :get, :index
      expect(response).to have_http_status(200)

      standard_groups = JSON.parse(response.body)['standard_groups']
      expect(standard_groups.size).to eq(StandardGroup.count)
    end
  end
end
