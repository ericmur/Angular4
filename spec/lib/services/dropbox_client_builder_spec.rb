require 'rails_helper'

RSpec.describe DropboxClientBuilder do
  let!(:auth_token) { Faker::Lorem.word }

  context '#call' do
    it 'return an instance of DropboxClient with authorization passed' do
      dropbox_client = DropboxClientBuilder.new(auth_token).get_client
      expect(dropbox_client.class).to eq(DropboxClient)
    end
  end
end
