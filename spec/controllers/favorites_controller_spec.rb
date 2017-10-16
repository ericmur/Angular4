require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe FavoritesController, type: :controller do
  before(:each) do
    load_standard_documents
    stub_docyt_support_creation
    setup_logged_in_consumer
    load_startup_keys
  end
  
  it 'should successfully create a favorite document' do
    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Birth Certificate' }).joins(:standard_base_document).first.standard_base_document
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])
    post :create, :format => :json, :favorite => { :document_id => doc.id }, :device_uuid => @device.device_uuid, :password_hash => @hsh
    expect(response.status).to eq(200)
  end

  it 'should add a Drivers License as favorite by default' do
    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])
    expect(doc.favorites.count).not_to eq(0)
  end

  it 'should not add a non default favorite document as favorite by default' do
    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Birth Certificate' }).joins(:standard_base_document).first.standard_base_document
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])
    expect(doc.favorites.count).to eq(0)
  end

  it 'should allow removing Drivers License from favorites even though its default' do
    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])

    expect(Favorite.count).to eq(1)
    #Remove from favorites
    delete :destroy, :format => :json, :id => doc.favorites.first.id, :device_uuid => @device.device_uuid
    expect(Favorite.count).to eq(0)
  end

  it 'should not add a document as a favorite more than once' do
    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])
    expect(Favorite.count).to eq(1)
    post :create, :format => :json, :favorite => { :document_id => doc.id }, :device_uuid => @device.device_uuid, :password_hash => @hsh
    expect(response.status).to eq(406)
  end

  it 'should allow multiple documents to be marked as favorites and set their ranks correctly' do
    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc1 = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])

    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Birth Certificate' }).joins(:standard_base_document).first.standard_base_document
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc2 = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])

    expect(Favorite.count).to eq(1)
    post :bulk_create, :format => :json, :favorite => [ { :document_id => doc1.id , :rank => 1}, { :document_id => doc2.id, :rank => 2 } ], :device_uuid => @device.device_uuid, :password_hash => @hsh
    expect(response.status).to eq(200)
    expect(Favorite.count).to eq(2)
    fav1 = @user.favorites.where(:document_id => doc1.id).first
    expect(fav1.rank).to eq(1)
    fav2 = @user.favorites.where(:document_id => doc2.id).first
    expect(fav2.rank).to eq(2)
  end

  it 'should return a list of favorites when requested' do
    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc1 = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])

    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Birth Certificate' }).joins(:standard_base_document).first.standard_base_document
    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    doc2 = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])
    FactoryGirl.create(:favorite, :document_id => doc2.id, :consumer_id => @user.id)

    get :index, :format => :json, :device_uuid => @device.device_uuid, :password_hash => @hsh
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    expect(res_json["favorites"].count).to eq(2)
  end
end
