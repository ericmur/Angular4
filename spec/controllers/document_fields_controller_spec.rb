require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe DocumentFieldsController, type: :controller do
  before(:each) do
    load_standard_documents
    stub_docyt_support_creation
    setup_logged_in_consumer
    load_startup_keys
  end

  it 'should create customer document fields' do
    standard_folder = StandardFolder.first
    standard_doc = StandardDocument.first
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc = FactoryGirl.create(:document, :standard_document_id => standard_doc.id, :consumer_id => @user.id, :document_owners => [doc_owner])
    post :create, :format => :json, :document_field => { :document_id => doc.id, :name => 'My first field', :data_type => 'string' }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    doc_field = DocumentField.where(:name => "My first field").first
    expect(res_json["document_field"]["id"]).to eq(doc_field.field_id)
    expect(doc_field).not_to eq(nil)
    expect(doc_field.document_id).to eq(doc.id)
    expect(doc_field.field_id).not_to eq(nil)
    expect(doc_field.created_by_user_id).to eq(@user.id)
    doc_field.reload
    expect(doc_field.field_id).to be >= (1000)
  end

  it 'should create customer document fields with expiry notifications' do
    standard_folder = StandardFolder.first
    standard_doc = StandardDocument.first
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc = FactoryGirl.create(:document, :standard_document_id => standard_doc.id, :consumer_id => @user.id, :document_owners => [doc_owner])
    post :create, :format => :json, :document_field => { :document_id => doc.id, :name => 'My first field', :data_type => 'expiry_date' }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    doc_field = DocumentField.where(:name => "My first field").first
    expect(doc_field).not_to eq(nil)
    expect(doc_field.document_id).to eq(doc.id)
    expect(doc_field.field_id).not_to eq(nil)
    expect(doc_field.created_by_user_id).to eq(@user.id)
    doc_field.reload
    expect(doc_field.notify_durations.count).to eq(NotifyDuration::DEFAULT_EXPIRY_NOTIFY_DURATIONS.count)
    expect(doc_field.field_id).to be >= (1000)
  end

  it 'should not create expiry notifications for a field which is not declared as date type' do
    standard_folder = StandardFolder.first
    standard_doc = StandardDocument.first
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc = FactoryGirl.create(:document, :standard_document_id => standard_doc.id, :consumer_id => @user.id, :document_owners => [doc_owner])
    post :create, :format => :json, :document_field => { :document_id => doc.id, :name => 'My first field', :data_type => 'string' }, :password_hash => @hsh, :device_uuid => @device.device_uuid

    expect(response.status).to eq(200)
    doc_field = DocumentField.where(:name => "My first field").first
    expect(doc_field.notify).to eq(false)
    expect(doc_field.notify_durations.count).to eq(0)
  end

  it 'should destroy customer document fields' do
    standard_folder = StandardFolder.first
    standard_doc = StandardDocument.first
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc = FactoryGirl.create(:document, :standard_document_id => standard_doc.id, :consumer_id => @user.id, :document_owners => [doc_owner])
    doc_field = DocumentField.create!(:document_id => doc.id, :name => 'My first field', :data_type => 'string', :created_by_user_id => @user.id)
    doc_field.reload
    delete :destroy, :format => :json, :id => doc_field.field_id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    doc_field = StandardDocumentField.where(:created_by_user_id => @user.id).first
    expect(doc_field).to eq(nil)
  end

  context "#create" do
    context "document cache service" do
      it 'should successfully enqueue document cache' do
        standard_folder = StandardFolder.first
        standard_doc = StandardDocument.first
        doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
        doc = FactoryGirl.create(:document, :standard_document_id => standard_doc.id, :consumer_id => @user.id, :document_owners => [doc_owner])

        expect(DocumentCacheService).to receive(:update_cache).with([:document], any_args).and_call_original

        post :create, :format => :json, :document_field => { :document_id => doc.id, :name => 'My first field', :data_type => 'string' }, :password_hash => @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end

      it 'should update owners and uploader document cache' do

        standard_folder = StandardFolder.first
        standard_doc = StandardDocument.first
        doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
        doc = FactoryGirl.create(:document, :standard_document_id => standard_doc.id, :consumer_id => @user.id, :document_owners => [doc_owner])

        expect(DocumentCacheService).to receive(:update_cache).with([:document], [@user.id]).and_call_original

        post :create, :format => :json, :document_field => { :document_id => doc.id, :name => 'My first field', :data_type => 'string' }, :password_hash => @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end
    end
  end

  context "#destroy" do
    context "document cache service" do
      it 'should successfully enqueue document cache' do
        standard_folder = StandardFolder.first
        standard_doc = StandardDocument.first
        doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
        doc = FactoryGirl.create(:document, :standard_document_id => standard_doc.id, :consumer_id => @user.id, :document_owners => [doc_owner])
        doc_field = DocumentField.create!(:document_id => doc.id, :name => 'My first field', :data_type => 'string', :created_by_user_id => @user.id)
        doc_field.reload

        expect(DocumentCacheService).to receive(:update_cache).with([:document], any_args).and_call_original

        delete :destroy, :format => :json, :id => doc_field.field_id, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end

      it 'should update owners and uploader document cache' do
        standard_folder = StandardFolder.first
        standard_doc = StandardDocument.first
        doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
        doc = FactoryGirl.create(:document, :standard_document_id => standard_doc.id, :consumer_id => @user.id, :document_owners => [doc_owner])
        doc_field = DocumentField.create!(:document_id => doc.id, :name => 'My first field', :data_type => 'string', :created_by_user_id => @user.id)
        doc_field.reload

        expect(DocumentCacheService).to receive(:update_cache).with([:document], [@user.id]).and_call_original

        delete :destroy, :format => :json, :id => doc_field.field_id, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end
    end
  end

end
