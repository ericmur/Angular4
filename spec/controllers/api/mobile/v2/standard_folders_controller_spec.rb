require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Mobile::V2::StandardFoldersController do
  before(:each) do
    load_standard_documents
    stub_docyt_support_creation
    setup_logged_in_consumer
    load_startup_keys
  end

  context "#create" do

    it 'should create customer category' do
      post :create, :format => :json, :standard_folder => { :name => "My Custom Category", :description => "Custom Category" }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      standard_folder = StandardFolder.where(:name => "My Custom Category").first
      expect(standard_folder.permissions.count).to eq(4) # VIEW, EDIT, DELETE, WRITE
      expect(standard_folder).not_to eq(nil)
      expect(standard_folder.rank).not_to eq(nil)
      expect(standard_folder.category).to eq(true)
    end

    it 'should require name and description when creating customer category' do
      post :create, :format => :json, :standard_folder => { :name => "", :description => "" }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(422)
    end

    context "document cache service" do
      it 'should successfully update standard folder cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:standard_folder], any_args).and_call_original
        post :create, :format => :json, :standard_folder => { :name => "My Custom Category", :description => "Custom Category" }, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end

      it 'should update owners and uploader document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:standard_folder], [@user.id]).and_call_original
        post :create, :format => :json, :standard_folder => { :name => "My Custom Category", :description => "Custom Category" }, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end
    end

    context "folder settings" do
      it 'should set standard folder visible for new owners'
    end

  end

end
