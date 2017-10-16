require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe DocumentsController, :type => :controller do
  before(:each) do
    stub_docyt_support_creation
    setup_logged_in_consumer
    load_startup_keys

    create(:standard_category)
  end

  it 'should require password for creating a document' do
    sbd = create_standard_document(@user)
    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :device_uuid => @device.device_uuid
    expect(response.status).to eq(406)
    res_json = JSON.parse(response.body)
    expect(Document.count).to eq(0)
    expect(res_json["errors"].first).to match(/Password .* required/)
  end

  it 'should require password for sharing a document' do
    sbd = create_standard_document(@user)
    FactoryGirl.create(:document, standard_document_id: sbd.id, consumer_id: @user.id, with_owner_list: [@user])

    group = FactoryGirl.create(:group, :owner => FactoryGirl.create(:consumer))
    group_user = FactoryGirl.create(:group_user, :user => @user, :group => group)

    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
    group_user = FactoryGirl.create(:group_user, :user => user2, :group => group)

    doc = Document.first

    put :share, :format => :json, :user_id => user2.id, :id => doc.id, :device_uuid => @device.device_uuid
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(406)

    expect(Document.count).to eq(1)
    expect(res_json["errors"].first).to match(/Password .* required/)
  end

  it 'should share with a list of users if you have share access' do
    sbd = create_standard_document(@user)

    group = FactoryGirl.create(:group, :owner => FactoryGirl.create(:consumer))
    group_user = FactoryGirl.create(:group_user, :user => @user, :group => group)

    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
    group_user = FactoryGirl.create(:group_user, :user => user2, :group => group)

    user3 = FactoryGirl.create(:consumer, :email => 'mitul@docyt.com')
    group_user = FactoryGirl.create(:group_user, :user => user3, :group => group)

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.first
    expect(SymmetricKey.count).to eq(1) # user's + system key
    put :share, :format => :json, :user_id => [user2.id, user3.id], :id => doc.id, :device_uuid => @device.device_uuid, :password_hash => @hsh
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(200)

    expect(SymmetricKey.count).to eq(3) # 3 users
    symmetric_key = doc.symmetric_keys.for_user_access(user3).first
    expect(symmetric_key.iv_encrypted).not_to eq(nil)
    expect(symmetric_key.key_encrypted).not_to eq(nil)
  end

  it 'should successfully return the list of categories' do
    load_standard_documents
    get :index, :format => :json, :category => "1", :device_uuid => @device.device_uuid, :password_hash => @hsh
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    expect(res_json["documents"].size).to eq(12)
    expect(res_json["documents"].map { |doc| [doc["name"], doc["category"], doc["rank"]] }).to eq(
       [["Invoices & Receipts", true, 1], ["Operations", true, 2], ["Certificates", true, 3], ["Contracts", true, 4], ["Financials", true, 5], ["Passwords", true, 6], ["Taxes", true, 7], ["Insurance/Claims", true, 8], ["Personal", true, 9], ["Travel", true, 10], ["Car", true, 11], ["Consumer", true, 12]]
    )
  end

  it 'should successfully return the list of all documents of a consumer' do
    sbd = create_standard_document(@user)
    FactoryGirl.create(:document, standard_document_id: sbd.id, consumer_id: @user.id, with_owner_list: [@user])
    FactoryGirl.create(:document, standard_document_id: sbd.id, consumer_id: @user.id, with_owner_list: [@user])

    get :index, :format => :json, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    expect(res_json["documents"].count).to eq(2)
  end

  it 'should successfully create a document and its symmetric keys and list the document in documents index call' do
    sbd = create_standard_document(@user)
    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    expect(Document.count).to eq(1)
    res_json = JSON.parse(response.body)
    expect(res_json["document"]["standard_document_id"]).to eq(sbd.id)
    expect(res_json["document"]["consumer_id"]).to eq(@user.id)
    expect(res_json["document"]["symmetric_key"]).not_to eq(nil)
    expect(res_json["document"]["symmetric_key"]).not_to eq('')

    get :index, :format => :json, :device_uuid => @device.device_uuid, :password_hash => @hsh
    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)

    expect(res_json["documents"].count).to eq(1)
    expect(res_json["documents"].first["symmetric_key"]).not_to eq(nil)
    expect(res_json["documents"].first["symmetric_key"]).not_to eq('')
    expect(res_json["documents"].first["consumer_id"]).to eq(@user.id)
  end

  it "should not give an error even if you try creating a document for a user who you don't have permissions for as long as you have them in your family group" do
    sbd = create_standard_document(@user)

    group = FactoryGirl.create(:group, :owner_id => @user.id)
    group_user = FactoryGirl.create(:group_user, :user => FactoryGirl.create(:consumer, :email => 'sid@vayuum.com'), :group => group)

    post :create, :format => :json, :document => { :standard_document_id => sbd.id, :document_owners => [{ :owner_id => group_user.id, :owner_type => 'GroupUser' }] }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(Document.count).to eq(1)
  end

  it 'should successfully share the document with a user in the group if you are the owner of the document' do
    sbd = create_standard_document(@user)

    group = FactoryGirl.create(:group, :owner => FactoryGirl.create(:consumer))
    group_user = FactoryGirl.create(:group_user, :user => @user, :group => group)

    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
    group_user = FactoryGirl.create(:group_user, :user => user2, :group => group)

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.first

    put :share, :format => :json, :user_id => user2.id, :id => doc.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(200)

    expect(Document.count).to eq(1)
    expect(SymmetricKey.where(:document_id => doc.id, :created_for_user_id => user2.id).count).to eq(1)
  end

  it 'should successfully share the document of another user in the group if that document is shared with the user' do
    sbd = create_standard_document(@user)

    group = FactoryGirl.create(:group, :owner => FactoryGirl.create(:consumer))
    group_user = FactoryGirl.create(:group_user, :user => @user, :group => group)

    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
    group_user = FactoryGirl.create(:group_user, :user => user2, :group => group)

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.first

    put :share, :format => :json, :user_id => user2.id, :id => doc.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(200)

    user3 = FactoryGirl.create(:consumer, :email => 'tedi@vayuum.com')
    group_user = FactoryGirl.create(:group_user, :user => user3, :group => group)

    put :share, :format => :json, :user_id => user3.id, :id => doc.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(200)

    expect(Document.count).to eq(1)
    expect(SymmetricKey.where(:document_id => doc.id, :created_for_user_id => user3.id).count).to eq(1)
  end

  it 'should not allow the user to share the document of another user in the group if that document is not shared with him' do
    sbd = create_standard_document(@user)

    group = FactoryGirl.create(:group, :owner => FactoryGirl.create(:consumer))
    group_user = FactoryGirl.create(:group_user, :user => @user, :group => group)

    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com')
    group_user = FactoryGirl.create(:group_user, :user => user2, :group => group)

    Rails.stub(:user_password_hash) { @hsh }
    doc_owner = FactoryGirl.build(:document_owner, :owner => user2)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => user2.id, :document_owners => [doc_owner])
    allow(Rails).to receive(:user_password_hash).and_call_original

    user3 = FactoryGirl.create(:consumer, :email => 'tedi@vayuum.com')
    group_user = FactoryGirl.create(:group_user, :user => user3, :group => group)

    put :share, :format => :json, :user_id => user3.id, :id => doc.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(406)
    expect(response.body).to match(/permissions to view/)
  end

  it 'should successfully show the shared document of another user with its symmetric key (system generated) when viewing that document' do
    sbd = create_standard_document(@user)

    user1 = @user
    user1_pin = @user_pin

    group = FactoryGirl.create(:group, :owner => FactoryGirl.create(:consumer))
    group_user = FactoryGirl.create(:group_user, :user => @user, :group => group)
    user2_pin = '234567'
    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)
    group_user = FactoryGirl.create(:group_user, :user => user2, :group => group)

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    setup_logged_in_consumer(user2, user2_pin)
    Rails.stub(:user_password_hash) { @hsh }

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.where(:consumer_id => user2.id).first
    put :share, :format => :json, :user_id => user1.id, :id => doc.id, :password_hash => @hsh, :device_uuid => @device.device_uuid

    expect(response.status).to eq(200)

    setup_logged_in_consumer(user1, user1_pin)
    Rails.stub(:user_password_hash) { @hsh }

    get :show, :format => :json, :id => doc.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(200)
    expect(res_json["document"]["id"]).to eq(doc.id)
    expect(res_json["document"]["symmetric_key"]["created_for_user_id"]).to eq(user1.id)
    sym_key = doc.symmetric_keys.where(:created_for_user_id => user1.id).first
    expect(res_json["document"]["symmetric_key"]["key"]).to eq(Base64.encode64(sym_key.decrypt_key))
  end

  it 'should not show another users document if it is not shared with the user' do
    sbd = create_standard_document(@user)

    user1 = @user
    user1_pin = @user_pin

    user2_pin = '234567'
    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)

    setup_logged_in_consumer(user2, user2_pin)

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.where(:consumer_id => user2.id).first

    setup_logged_in_consumer(user1, user1_pin)
    Rails.stub(:user_password_hash) { @hsh }

    get :show, :format => :json, :id => doc.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(406)
    expect(response.body).to match(/permissions to view/)
  end

  it 'should only allow you to destroy a document you own' do
    user1 = @user
    user1_pin = @user_pin
    sbd = create_standard_document(@user)

    user2_pin = '234567'
    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)
    Rails.stub(:user_password_hash) { user2.password_hash(user2_pin) }
    doc_owner = FactoryGirl.build(:document_owner, :owner => user2)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => user2.id, :document_owners => [doc_owner])
    expect(Document.count).to eq(1)
    delete :destroy, :format => :json, :id => doc.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(406)
    expect(Document.count).to eq(1)

    Rails.stub(:user_password_hash) { @hsh }
    doc_owner = FactoryGirl.build(:document_owner, :owner => user1)
    doc2 = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => user1.id, :document_owners => [doc_owner])
    expect(Document.count).to eq(2)
    delete :destroy, :format => :json, :id => doc2.id, :device_uuid => @device.device_uuid
    expect(response.status).to eq(204)
    expect(Document.count).to eq(1)
    expect(Document.first.id).to eq(doc.id)
  end

  it 'should only allow you to destroy another users document that you have permission to' # do
  #   user1 = @user
  #   user1_pin = @user_pin
  #   sf = StandardFolder.where(:name => 'Personal', :category => true).first
  #   sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
  #   user2_pin = '234567'
  #   user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)
  #   Rails.stub(:user_password_hash) { user2.password_hash(user2_pin) }
  #   doc_owner = FactoryGirl.build(:document_owner, :owner => user2)
  #   doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => user2.id, :document_owners => [doc_owner])
  #   expect(Document.count).to eq(1)

  #   setup_logged_in_consumer(user2, user2_pin)

  #   doc = Document.where(:consumer_id => user2.id).first
  #   put :share, :format => :json, :user_id => user1.id, :id => doc.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
  #   expect(response.status).to eq(200)

  #   setup_logged_in_consumer(user1, user1_pin)

  #   delete :destroy, :format => :json, :id => doc.id, :device_uuid => @device.device_uuid
  #   expect(response.status).to eq(406)
  #   expect(Document.count).to eq(1)

  #   user_access = FactoryGirl.create(:user_access, :user => user2, :accessor_id => user1.id)

  #   delete :destroy, :format => :json, :id => doc.id, :device_uuid => @device.device_uuid
  #   expect(response.status).to eq(204)
  #   expect(Document.count).to eq(0)
  # end

  it 'should successfully revoke the access to a document for a user who the document is shared with if you are the owner of that document' do
    user1 = @user
    user1_pin = @user_pin

    sbd = create_standard_document(@user)

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.where(:consumer_id => @user.id).first
    expect(doc.symmetric_keys.count).to eq(1) # user's
    user2_pin = '234567'
    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)
    doc.share_with(:by_user_id => @user.id, :with_user_id => user2.id)
    doc.symmetric_keys.reload
    expect(doc.symmetric_keys.count).to eq(2) # 2 users
    put :revoke, :format => :json, :id => doc.id, :user_id => user2.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(doc.symmetric_keys.count).to eq(1) # user's
    expect(doc.symmetric_keys.first.created_for_user_id).to eq(@user.id)
  end

  it 'should successfully archive the symmetric key when access to a document for a user is revoked' do
    user1 = @user
    user1_pin = @user_pin

    sbd = create_standard_document(@user)

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.where(:consumer_id => @user.id).first
    expect(doc.symmetric_keys.count).to eq(1) # user's
    user2_pin = '234567'
    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)
    doc.share_with(:by_user_id => @user.id, :with_user_id => user2.id)
    doc.symmetric_keys.reload
    expect(doc.symmetric_keys.count).to eq(2) # 2 users
    symm_key = doc.symmetric_keys.last
    expect(SymmetricKeyArchive.count).to eq(0)
    put :revoke, :format => :json, :id => doc.id, :user_id => user2.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(SymmetricKeyArchive.count).to eq(1)
    arch = SymmetricKeyArchive.first
    expect(arch.created_for_user_id).to eq(symm_key.created_for_user_id)
    expect(arch.created_by_user_id).to eq(symm_key.created_by_user_id)
    expect(arch.document_id).to eq(symm_key.document_id)
    expect(arch.symmetric_key_created_at).to eq(symm_key.created_at)
  end

  it 'should successfully revoke the access to a document for a user who the document is shared with if you are group_user of that document' do
    sbd = create_standard_document(@user)

    group = FactoryGirl.create(:group, :owner_id => @user.id)
    user1_pin = '123567'
    user1 = FactoryGirl.create(:consumer, :email => 'tedi@vayuum.com', :pin => user1_pin, :pin_confirmation => user1_pin)
    group_user = FactoryGirl.create(:group_user, :group => group, :user => nil)
    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :document_owners => [{ :owner_id => group_user.id, :owner_type => 'GroupUser' }], :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    group_user.set_user(user1.id)
    DocumentAccessRequest.process_access_request_for_user(@user, user1)

    doc = Document.where(:consumer_id => @user.id).first

    expect(doc.symmetric_keys.count).to eq(2) # 2 users
    user2_pin = '234567'
    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)

    setup_logged_in_consumer(user1, user1_pin)
    Rails.stub(:user_password_hash) { user1.password_hash(user1_pin) }
    doc.share_with(:by_user_id => user1.id, :with_user_id => user2.id)
    doc.symmetric_keys.reload
    expect(doc.symmetric_keys.count).to eq(3) # 3 users
    put :revoke, :format => :json, :id => doc.id, :user_id => user2.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(doc.symmetric_keys.count).to eq(2) # 2 users
    expect(doc.symmetric_keys.map(&:created_for_user_id)).to include(@user.id)
    expect(doc.symmetric_keys.map(&:created_for_user_id)).to include(user1.id)
  end

  it 'should successfully revoke the access to a document for a user who the document is shared with if you have permissions to manage that users documents (i.e. you are head of household appointed by that user)' # do
  #   sf = StandardFolder.where(:name => 'Personal', :category => true).first
  #   sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
  #   post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
  #   expect(response.status).to eq(200)

  #   doc = Document.where(:consumer_id => @user.id).first
  #   expect(doc.symmetric_keys.count).to eq(1) # user's
  #   user2_pin = '234567'
  #   user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)

  #   ua = @user.user_accessors.build(:accessor_id => user2.id)
  #   res = ua.save_with_keys
  #   expect(res).to eq(true)

  #   #Login Head of household
  #   setup_logged_in_consumer(user2, user2_pin)
  #   user3_pin = '234578'
  #   user3 = FactoryGirl.create(:consumer, :email => 'tedi@vayuum.com', :pin => user3_pin, :pin_confirmation => user3_pin)

  #   Rails.stub(:user_password_hash) { @hsh }
  #   doc.share_with(:by_user_id => @user.id, :with_user_id => user3.id)
  #   doc.symmetric_keys.reload
  #   expect(doc.symmetric_keys.count).to eq(3) # 3 users
  #   put :revoke, :format => :json, :id => doc.id, :user_id => user3.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
  #   expect(response.status).to eq(200)
  #   expect(doc.symmetric_keys.count).to eq(2) # 2 users
  #   expect(doc.symmetric_keys.map(&:created_for_user_id)).to include(@user.id)
  #   expect(doc.symmetric_keys.map(&:created_for_user_id)).to include(user2.id)
  # end

  it 'should throw an error if you try to revoke the access to a document for a user who does not have access to the document'
=begin
  # FIXME: check re-implementation of :revoke action
  it 'should throw an error if you try to revoke the access to a document for a user who does not have access to the document' do
    user1 = @user
    user1_pin = @user_pin
    sf = StandardFolder.where(:name => 'Personal', :category => true).first
    sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.where(:consumer_id => @user.id).first
    expect(doc.symmetric_keys.count).to eq(1) # user's
    user2_pin = '234567'
    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)

    expect {
      put :revoke, :format => :json, :id => doc.id, :user_id => user2.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    }.to raise_error
  end
=end

  it 'should not allow you to revoke access for a document that you dont own or have user_access to' do
    user1 = @user
    user1_pin = @user_pin
    sbd = create_standard_document(@user)

    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.where(:consumer_id => @user.id).first
    expect(doc.symmetric_keys.count).to eq(1) # user's
    user2_pin = '234567'
    user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)
    doc.share_with(:by_user_id => @user.id, :with_user_id => user2.id)
    doc.symmetric_keys.reload
    expect(doc.symmetric_keys.count).to eq(2) # users

    user3_pin = '345678'
    user3 = FactoryGirl.create(:consumer, :email => 'tedi@vayuum.com', :pin => user3_pin, :pin_confirmation => user3_pin)

    setup_logged_in_consumer(user3, user3_pin)
    put :revoke, :format => :json, :id => doc.id, :user_id => user2.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(406)
    res_json = JSON.parse(response.body)
    expect(res_json["errors"].first).to match(/permissions to revoke/)
  end

  describe 'Phone Confirmation' do

    it 'should not allow user to continue using the app when phone is not confirmed' do
      user2_pin = '234567'
      user2 = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => user2_pin, :pin_confirmation => user2_pin)

      user2.phone_confirmed_at = nil
      user2.save

      setup_logged_in_consumer(user2, user2_pin)

      sbd = create_standard_document(@user)

      post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid

      expect(response.status).to eq(403)
      expect(JSON.parse(response.body)['errors']).to include('Confirmed phone number is required to use the application')
    end

  end

  it 'should successfully show the pages of a users document and its symmetric key'

  it 'should successfully return the correct list of documents of group_users in the group owned by consumer'

  it 'should successfully return the correct list of base_documents including a custom base_document of consumer and his group_users'

  it 'should show myself as shared with when document belongs to a group user who is not connected' do
    sbd = create_standard_document(@user)

    group = FactoryGirl.create(:group, :owner_id => @user.id)
    group_user = FactoryGirl.create(:group_user, :group => group, :user => nil)

    doc_owner = FactoryGirl.build(:document_owner, :owner => group_user)
    doc = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])

    get :sharees, :format => :json, :id => doc.id, :device_uuid => @device.device_uuid

    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    expect(res_json["sharees"].count).to eq(1) # user
    expect(SymmetricKey.count).to eq(1)
  end

  it 'should show another user too who document is shared with if document belongs to a connected group user and document is shared with me' do
    sbd = create_standard_document(@user)

    user = @user
    user_pin = @user_pin
    group = FactoryGirl.create(:group, :owner_id => @user.id)
    group_user = FactoryGirl.create(:group_user, :group => group, :user => nil)
    user2 = FactoryGirl.create(:consumer) #another user to share with
    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :document_owners => [{ :owner_id => group_user.id, :owner_type => 'GroupUser' }], :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    group_user_user_pin = @user_pin
    group_user_user =  FactoryGirl.create(:consumer, :pin => group_user_user_pin, :pin_confirmation => group_user_user_pin)
    group_user.set_user(group_user_user.id)
    DocumentAccessRequest.process_access_request_for_user(@user, group_user_user)
    doc = Document.first

    setup_logged_in_consumer(group_user_user, group_user_user_pin)
    Rails.stub(:user_password_hash) { @hsh }
    doc.share_with(:by_user_id => group_user.user_id, :with_user_id => user2.id)

    setup_logged_in_consumer(user, user_pin)
    get :sharees, :format => :json, :id => doc.id, :device_uuid => @device.device_uuid

    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    expect(res_json["sharees"].count).to eq(2)
    expect(SymmetricKey.count).to eq(3) #user, user2, group_user_user
    expect(res_json["sharees"].map { |res| res["id"] }).to include(user.id)
    expect(res_json["sharees"].map { |res| res["id"] }).to include(user2.id)
  end

  it 'should show all users who document is shared with if I am the only document owner' do
    sbd = create_standard_document(@user)
    user = @user
    user_pin = @user_pin
    group = FactoryGirl.create(:group, :owner_id => @user.id)
    group_user = FactoryGirl.create(:group_user, :group => group, :user => nil)
    user2 = FactoryGirl.create(:consumer) #another user to share with
    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :document_owners => [{ :owner_id => group_user.id, :owner_type => 'GroupUser' }], :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    group_user_user_pin = @user_pin
    group_user_user =  FactoryGirl.create(:consumer, :pin => group_user_user_pin, :pin_confirmation => group_user_user_pin)
    group_user.set_user(group_user_user.id)
    DocumentAccessRequest.process_access_request_for_user(@user, group_user_user)

    doc = Document.first

    setup_logged_in_consumer(group_user_user, group_user_user_pin)
    Rails.stub(:user_password_hash) { @hsh }
    doc.share_with(:by_user_id => group_user.user_id, :with_user_id => user2.id)

    get :sharees, :format => :json, :id => doc.id, :device_uuid => @device.device_uuid

    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    expect(res_json["sharees"].count).to eq(2)
    expect(SymmetricKey.count).to eq(3) #user, user2, group_user_user
    expect(res_json["sharees"].map { |d| d["id"] }).to include(user.id)
    expect(res_json["sharees"].map { |d| d["id"] }).to include(user2.id)
  end

  it 'should allow to delete another share if user is the owner' do
    sbd = create_standard_document(@user)

    user = @user
    user_pin = @user_pin
    group = FactoryGirl.create(:group, :owner_id => @user.id)
    group_user = FactoryGirl.create(:group_user, :group => group, :user => nil)

    user2 = FactoryGirl.create(:consumer) #another user to share with
    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :document_owners => [{ :owner_id => group_user.id, :owner_type => 'GroupUser' }, { :owner_id => user.id, :owner_type => 'User' }], :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    group_user_user_pin = @user_pin
    group_user_user =  FactoryGirl.create(:consumer, :pin => group_user_user_pin, :pin_confirmation => group_user_user_pin)
    group_user.set_user(group_user_user.id)
    DocumentAccessRequest.process_access_request_for_user(@user, group_user_user)
    doc = Document.first

    setup_logged_in_consumer(user, user_pin)
    Rails.stub(:user_password_hash) { @hsh }
    doc.share_with(:by_user_id => user.id, :with_user_id => group_user.user_id)
    DocumentPermission.create(document: doc, user: user, value: DocumentPermission::EDIT_SHAREE, user_type: DocumentPermission::OWNER)

    put :update_sharees, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id, document_sharees: [{ user_id: group_user.user_id, delete: '1' }]
    expect(response.status).to eq(200)

    expect(SymmetricKey.count).to eq(1) #user
  end

  it 'should not allow to delete another sharee if user is a sharee' do
    sbd = create_standard_document(@user)

    user = @user
    user_pin = @user_pin
    group = FactoryGirl.create(:group, :owner_id => @user.id)
    group_user = FactoryGirl.create(:group_user, :group => group, :user => nil)
    user2 = FactoryGirl.create(:consumer) #another user to share with
    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :document_owners => [{ :owner_id => user.id, :owner_type => 'User' }], :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    doc = Document.first
    setup_logged_in_consumer(user, user_pin)
    Rails.stub(:user_password_hash) { @hsh }
    doc.share_with(:by_user_id => user.id, :with_user_id => group_user.user_id)

    group_user_user_pin = @user_pin
    group_user_user =  FactoryGirl.create(:consumer, :pin => group_user_user_pin, :pin_confirmation => group_user_user_pin)
    group_user.set_user(group_user_user.id)
    DocumentAccessRequest.process_access_request_for_user(@user, group_user_user)

    setup_logged_in_consumer(group_user_user, group_user_user_pin)
    Rails.stub(:user_password_hash) { @hsh }

    put :update_sharees, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id, document_sharees: [{ user_id: user.id, delete: '1' }]
    expect(response.status).to eq(406)

    expect(SymmetricKey.count).to eq(2) # user, group_user_user
  end

  it 'should allow to delete myself as sharee' # do
  #   sf = StandardFolder.where(:name => 'Personal', :category => true).first
  #   sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
  #   user = @user
  #   user_pin = @user_pin
  #   group = FactoryGirl.create(:group, :owner_id => @user.id)
  #   group_user = FactoryGirl.create(:group_user, :group => group, :user => nil)

  #   group_user_user_pin = @user_pin
  #   group_user_user =  FactoryGirl.create(:consumer, :pin => group_user_user_pin, :pin_confirmation => group_user_user_pin)
  #   group_user.set_user(group_user_user.id)
  #   DocumentAccessRequest.process_access_request_for_user(@user, group_user_user)

  #   post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :document_owners => [ { :owner_id => group_user_user.id, :owner_type => 'User' }], :password_hash => @hsh, :device_uuid => @device.device_uuid
  #   expect(response.status).to eq(200)

  #   doc = Document.first
  #   setup_logged_in_consumer(user, user_pin)
  #   Rails.stub(:user_password_hash) { @hsh }
  #   doc.share_with(:by_user_id => group_user_user.id, :with_user_id => user.id)

  #   put :update_sharees, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id, document_sharees: [{ user_id: user.id, delete: '1' }]

  #   expect(response.status).to eq(200)
  #   expect(SymmetricKey.count).to eq(1) # group_user_user
  # end

  it 'should show all users who document is shared with if I and another user are document owners' do
    sbd = create_standard_document(@user)

    user = @user
    user_pin = @user_pin
    group = FactoryGirl.create(:group, :owner_id => @user.id)
    group_user = FactoryGirl.create(:group_user, :group => group, :user => nil)
    user2 = FactoryGirl.create(:consumer) #another user to share with
    post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :document_owners => [{ :owner_id => group_user.id, :owner_type => 'GroupUser' }, { :owner_id => user.id, :owner_type => 'User' }], :password_hash => @hsh, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)

    group_user_user_pin = @user_pin
    group_user_user =  FactoryGirl.create(:consumer, :pin => group_user_user_pin, :pin_confirmation => group_user_user_pin)
    group_user.set_user(group_user_user.id)
    DocumentAccessRequest.process_access_request_for_user(@user, group_user_user)
    doc = Document.first

    setup_logged_in_consumer(group_user_user, group_user_user_pin)
    Rails.stub(:user_password_hash) { @hsh }
    doc.share_with(:by_user_id => group_user.user_id, :with_user_id => user2.id)

    setup_logged_in_consumer(user, user_pin)
    get :sharees, :format => :json, :id => doc.id, :device_uuid => @device.device_uuid

    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)
    expect(res_json["sharees"].count).to eq(1) #Belongs to group_user_user and user. But shared with just user2
    expect(SymmetricKey.count).to eq(3) #user, user2, group_user_user
    expect(res_json["sharees"].map { |d| d["id"] }).to include(user2.id)
  end

  context "#create" do

    context "document cache service" do
      it 'should successfully enqueue document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document, :folder_setting], any_args).and_call_original

        sbd = create_custom_standard_folder_standard_document(@user)
        post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end

      it 'should not enqueue document cache when creation failed' do
        expect(DocumentCacheService).not_to receive(:update_cache).with([:document, :folder_setting], any_args)

        sbd = create_custom_standard_folder_standard_document(@user)
        post :create, :format => :json, :document => { :standard_document_id => sbd.id }
        expect(response.status).to eq(403)
      end

      it 'should update document owners and uploader cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document, :folder_setting], [@user.id]).and_call_original

        sbd = create_custom_standard_folder_standard_document(@user)
        post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid

        expect(response.status).to eq(200)
      end
    end

    context "permissions", permissions: true do

      it 'should create permissions VIEW, EDIT, DELETE for owner' do
        sbd = create_custom_standard_folder_standard_document(@user)
        post :create, :format => :json, :document => { :standard_document_id => sbd.id }, :password_hash => @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        Permission::VALUES.each do |v|
          expect(@standard_document.permissions.where(user_id: @user.id, value: v).count).to eq(1)
          expect(@standard_folder.permissions.where(user_id: @user.id, value: v).count).to eq(1)
        end

        expect(@standard_document.permissions.where(user_id: @user.id, folder_structure_owner: @user).count).to eq(4)
        expect(@standard_folder.permissions.where(user_id: @user.id, folder_structure_owner: @user).count).to eq(4)
      end

      it 'should create permissions for group owner to group_user\'s folder' do
        group_user = create_group_user_for(@user)
        sbd = create_custom_standard_folder_standard_document(group_user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [{
              owner_id: group_user.id, owner_type: 'GroupUser'
            }],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        expect(@standard_document.permissions.where(user_id: @user.id, folder_structure_owner: @user).count).to eq(0)
        expect(@standard_folder.permissions.where(user_id: @user.id, folder_structure_owner: @user).count).to eq(0)

        expect(@standard_document.permissions.where(user_id: @user.id, folder_structure_owner: group_user).count).to eq(4)
        expect(@standard_folder.permissions.where(user_id: @user.id, folder_structure_owner: group_user).count).to eq(4)

        Permission::VALUES.each do |v|
          expect(@standard_document.permissions.where(user_id: @user.id, folder_structure_owner: group_user, value: v).count).to eq(1)
          expect(@standard_folder.permissions.where(user_id: @user.id, folder_structure_owner: group_user, value: v).count).to eq(1)
        end
      end

      it 'should create permissions for group owner and group_user' do
        group_user = create_group_user_for(@user)
        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' },
              { owner_id: group_user.id, owner_type: 'GroupUser' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        expect(@standard_document.permissions.where(user_id: @user.id, folder_structure_owner: @user).count).to eq(4)
        expect(@standard_folder.permissions.where(user_id: @user.id, folder_structure_owner: @user).count).to eq(4)
        expect(@standard_document.permissions.where(user_id: @user.id, folder_structure_owner: group_user).count).to eq(4)
        expect(@standard_folder.permissions.where(user_id: @user.id, folder_structure_owner: group_user).count).to eq(4)

        Permission::VALUES.each do |v|
          expect(@standard_document.permissions.where(user_id: @user.id, folder_structure_owner: @user, value: v).count).to eq(1)
          expect(@standard_folder.permissions.where(user_id: @user.id, folder_structure_owner: @user, value: v).count).to eq(1)
          expect(@standard_document.permissions.where(user_id: @user.id, folder_structure_owner: group_user, value: v).count).to eq(1)
          expect(@standard_folder.permissions.where(user_id: @user.id, folder_structure_owner: group_user, value: v).count).to eq(1)
        end
      end

      it 'should create correct permissions when document owned by 2 users (1 connected, 1 current user) and 1 unconnected group user' do
        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)
        group = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)

        group_user2 = create_group_user_for(@user, user2, group)
        group_user = create_group_user_for(@user, nil, group)
        group_user3 = create_group_user_for(user2, @user, group2)

        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' },
              { owner_id: user2.id, owner_type: 'User' },
              { owner_id: group_user.id, owner_type: 'GroupUser' }

            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        # 4 for @user to @user
        # 4 for @user to user2
        # 4 for @user to group_user
        expect(@standard_document.permissions.where(user_id: @user.id).count).to eq(12)

        # 4 for user2 to @user
        # 4 for user2 to user2
        expect(@standard_document.permissions.where(user_id: user2.id).count).to eq(8)
      end

      it 'should create correct permissions when document owned by 1 connected user and 1 unconnected group user' do
        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)
        group = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)

        group_user2 = create_group_user_for(@user, user2, group)
        group_user = create_group_user_for(@user, nil, group)
        group_user3 = create_group_user_for(user2, @user, group2)

        sbd = create_custom_standard_folder_standard_document(group_user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: user2.id, owner_type: 'User' },
              { owner_id: group_user.id, owner_type: 'GroupUser' }

            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        # 3 for @user to user2
        # 3 for @user to group_user
        expect(@standard_document.permissions.where(user_id: @user.id).count).to eq(8)

        # 3 from user2 to user2
        expect(@standard_document.permissions.where(user_id: user2.id).count).to eq(4)
      end

      it 'should create correct permissions when document owned by 2 connected contacts and 1 unconnected group user' do
        # Connection setup
        #     User1        User2     User3
        # ---------------------------------
        # - group_user1   - @user   - @user
        # - user2
        # - user3

        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)
        user3 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)
        group3 = FactoryGirl.create(:group, owner_id: user3.id, standard_group: standard_group)

        group_user2 = create_group_user_for(@user, user2, group1)
        group_user3 = create_group_user_for(@user, user3, group1)

        group_user4 = create_group_user_for(user2, @user, group2)
        group_user5 = create_group_user_for(user3, @user, group3)

        group_user1 = create_group_user_for(@user, nil, group1)

        sbd = create_custom_standard_folder_standard_document(group_user1)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: user2.id, owner_type: 'User' },
              { owner_id: user3.id, owner_type: 'User' },
              { owner_id: group_user1.id, owner_type: 'GroupUser' }

            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        # 4 for @user to user2
        # 4 for @user to user3
        # 4 for @user to group_user
        expect(@standard_document.permissions.where(user_id: @user.id).count).to eq(12)

        # 4 from user2 to user2
        expect(@standard_document.permissions.where(user_id: user2.id).count).to eq(8)
        expect(@standard_document.permissions.where(user_id: user2.id, folder_structure_owner: user3).count).to eq(4)

        # 4 from user3 to user3
        expect(@standard_document.permissions.where(user_id: user3.id).count).to eq(8)
        expect(@standard_document.permissions.where(user_id: user3.id, folder_structure_owner: user2).count).to eq(4)
      end

    end

  end

  context "#destroy" do

    context "document cache service" do
      it 'should successfully enqueue document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], any_args).and_call_original

        sbd = create_standard_document(@user)

        Rails.stub(:user_password_hash) { @hsh }

        doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
        @document = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])
        allow(Rails).to receive(:user_password_hash).and_call_original

        delete :destroy, :format => :json, :id => @document.id, :device_uuid => @device.device_uuid
      end

      it 'should update document owners and uploader cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], [@user.id]).and_call_original

        sbd = create_standard_document(@user)

        Rails.stub(:user_password_hash) { @hsh }

        doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
        @document = FactoryGirl.create(:document, :standard_document_id => sbd.id, :consumer_id => @user.id, :document_owners => [doc_owner])
        allow(Rails).to receive(:user_password_hash).and_call_original

        delete :destroy, :format => :json, :id => @document.id, :device_uuid => @device.device_uuid
      end
    end

    context "permissions", permissions: true do
      it 'should not destroy standard base document permissions' do
        standard_group = FactoryGirl.create(:standard_group)
        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        delete :destroy, :format => :json, :id => @document.id, :device_uuid => @device.device_uuid

        expect(@standard_document.permissions.where(user_id: @user.id).count).to eq(4)
        expect(@standard_folder.permissions.where(user_id: @user.id).count).to eq(4)
      end
    end

  end

  context "#update_sharees" do

    context "document cache service" do
      it 'should successfully enqueue document cache' do

        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)

        group_user1 = create_group_user_for(@user, user2, group1)
        group_user2 = create_group_user_for(user2, @user, group2)

        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        doc = Document.first

        expect(DocumentCacheService).to receive(:update_cache).with([:standard_folder, :standard_document, :document, :folder_setting], any_args).and_call_original
        put :update_sharees, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id, document_sharees: [{ user_id: user2.id }]
        expect(response.status).to eq(200)
      end

      it 'should update document owners and uploader cache' do

        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)

        group_user1 = create_group_user_for(@user, user2, group1)
        group_user2 = create_group_user_for(user2, @user, group2)

        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        doc = Document.first

        expect(DocumentCacheService).to receive(:update_cache).with([:standard_folder, :standard_document, :document, :folder_setting], [@user.id, user2.id]).and_call_original
        put :update_sharees, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id, document_sharees: [{ user_id: user2.id }]
        expect(response.status).to eq(200)
      end
    end

    context "permissions", permissions: true do
      it 'should create VIEW permission when document is shared' do
        # Connection setup
        #     User1        User2
        # ------------------------
        # - user2         - @user

        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)

        group_user1 = create_group_user_for(@user, user2, group1)
        group_user2 = create_group_user_for(user2, @user, group2)

        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        doc = Document.first

        put :update_sharees, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id, document_sharees: [{ user_id: user2.id }]
        expect(response.status).to eq(200)
        expect(SymmetricKey.count).to eq(2)

        expect(doc.standard_document.permissions.count).to eq(5)
        expect(doc.standard_document.permissions.where(user_id: user2.id).count).to eq(1) # VIEW Permission for user2
      end
    end

    context 'folder settings' do
      it 'should set standard folder visible for new sharees' do
        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)

        group_user1 = create_group_user_for(@user, user2, group1)
        group_user2 = create_group_user_for(user2, @user, group2)

        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        doc = Document.first

        put :update_sharees, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id, document_sharees: [{ user_id: user2.id }]
        expect(response.status).to eq(200)

        expect(UserFolderSetting.where(user_id: user2, standard_base_document_id: doc.standard_document_id).count).to eq(0)
        doc.standard_document.standard_folder_standard_documents.each do |sfsd|
          fs = UserFolderSetting.where(user_id: user2, standard_base_document_id: sfsd.standard_folder_id)
          expect(fs.count).to eq(1)
          expect(fs.first.displayed).to eq(true)
        end
      end

      it 'should set standard document visible for new sharees with FLAT structure' do
        # Connection setup
        #   User1           User2
        # ------------------------
        # - user2 (FOLDER)  - @user (FLAT)

        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)

        group_user1 = create_group_user_for(@user, user2, group1)
        # user2 has @user in his contact list with FLAT folder structure
        group_user2 = create_group_user_for(user2, @user, group2, GroupUser::FLAT)

        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        doc = Document.first

        put :update_sharees, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id, document_sharees: [{ user_id: user2.id }]
        expect(response.status).to eq(200)

        fs = UserFolderSetting.where(user_id: user2, standard_base_document_id: doc.standard_document_id)
        expect(fs.count).to eq(1)
        expect(fs.first.displayed).to eq(true)

        doc.standard_document.standard_folder_standard_documents.each do |sfsd|
          expect(UserFolderSetting.where(user_id: user2, standard_base_document_id: sfsd.standard_folder_id).count).to eq(0)
        end
      end
    end

  end

  context "#update" do
    it "should allow setting owners of a document for the chat user if document was sent via chat"
  end

  context "#update_owners" do

    context "document cache service" do
      it 'should successfully enqueue document cache' do
        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)
        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group_user1 = create_group_user_for(@user, nil, group1)
        sbd = create_custom_standard_folder_standard_document(group_user1)
        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: group_user1.id, owner_type: 'GroupUser' }

            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        expect(DocumentCacheService).to receive(:update_cache).with([:standard_folder, :standard_document, :document, :folder_setting], any_args).and_call_original

        put :update_owners, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: @document.id,
          document_owners: [
            { owner_id: user2.id, owner_type: 'User' }
          ]
        expect(response.status).to eq(200)
      end

      it 'should update document owners and uploader cache' do
        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)
        user3 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)
        group3 = FactoryGirl.create(:group, owner_id: user3.id, standard_group: standard_group)

        group_user2 = create_group_user_for(@user, user2, group1)
        group_user3 = create_group_user_for(@user, user3, group1)

        group_user4 = create_group_user_for(user2, @user, group2)
        group_user5 = create_group_user_for(user3, @user, group3)

        group_user1 = create_group_user_for(@user, nil, group1)
        sbd = create_custom_standard_folder_standard_document(group_user1)
        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: group_user1.id, owner_type: 'GroupUser' }

            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        expect(DocumentCacheService).to receive(:update_cache).with([:standard_folder, :standard_document, :document, :folder_setting], [@user.id, user2.id]).and_call_original

        put :update_owners, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: @document.id,
          document_owners: [
            { owner_id: user2.id, owner_type: 'User' }
          ]


        @document.reload
      end
    end

    context "permissions", permissions: true do
      it 'should create VIEW, EDIT, DELETE permissions for new added contacts' do
        # Connection setup
        #     User1        User2     User3
        # ---------------------------------
        # - group_user1   - @user   - @user
        # - user2
        # - user3

        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)
        user3 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)
        group3 = FactoryGirl.create(:group, owner_id: user3.id, standard_group: standard_group)

        group_user2 = create_group_user_for(@user, user2, group1)
        group_user3 = create_group_user_for(@user, user3, group1)

        group_user4 = create_group_user_for(user2, @user, group2)
        group_user5 = create_group_user_for(user3, @user, group3)

        group_user1 = create_group_user_for(@user, nil, group1)

        sbd = create_custom_standard_folder_standard_document(group_user1)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: group_user1.id, owner_type: 'GroupUser' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        # 4 for @user to group_user
        expect(@standard_document.permissions.where(user_id: @user.id).count).to eq(4)
        expect(@standard_document.permissions.where(user_id: user2.id).count).to eq(0)
        expect(@standard_document.permissions.where(user_id: user3.id).count).to eq(0)

        doc = Document.first
        put :update_owners, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id,
          document_owners: [
            { owner_id: user2.id, owner_type: 'User' }
          ]

        # 4 from user2 to user2
        expect(@standard_document.permissions.where(user_id: user2.id).count).to eq(4)

        put :update_owners, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id,
          document_owners: [
            { owner_id: user3.id, owner_type: 'User' }
          ]

        # no additional permissions for user2
        expect(@standard_document.permissions.where(user_id: user2.id).count).to eq(8)
        # 4 from user3 to user3
        expect(@standard_document.permissions.where(user_id: user3.id).count).to eq(8)
      end

      it 'should not remove standard base document permissions' do
                # Connection setup
        #     User1        User2     User3
        # ---------------------------------
        # - group_user1   - @user   - @user
        # - user2
        # - user3

        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)
        user3 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)
        group3 = FactoryGirl.create(:group, owner_id: user3.id, standard_group: standard_group)

        group_user2 = create_group_user_for(@user, user2, group1)
        group_user3 = create_group_user_for(@user, user3, group1)

        group_user4 = create_group_user_for(user2, @user, group2)
        group_user5 = create_group_user_for(user3, @user, group3)

        group_user1 = create_group_user_for(@user, nil, group1)

        sbd = create_custom_standard_folder_standard_document(group_user1)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: group_user1.id, owner_type: 'GroupUser' }

            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        @document, @standard_document, @standard_folder = get_first_document_and_standard_document

        # 3 for @user to group_user
        expect(@standard_document.permissions.where(user_id: @user.id).count).to eq(4)
        expect(@standard_document.permissions.where(user_id: user2.id).count).to eq(0)
        expect(@standard_document.permissions.where(user_id: user3.id).count).to eq(0)

        doc = Document.first
        put :update_owners, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id,
          document_owners: [
            { owner_id: user2.id, owner_type: 'User' }
          ]

        expect(doc.document_owners.count).to eq(2)
        # 3 from user2 to user2
        expect(@standard_document.permissions.where(user_id: user2.id).count).to eq(4)

        put :update_owners, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id,
          document_owners: [
            { owner_id: user2.id, owner_type: 'User', delete: '1' }
          ]

        expect(doc.document_owners.count).to eq(1)
        # user2 permission for standard document should not deleted
        expect(@standard_document.permissions.where(user_id: user2.id).count).to eq(4)
      end
    end

    context 'folder settings' do
      it 'should set standard folder visible for new owners' do
        # Connection setup
        #   User1           User2
        # ------------------------
        # - user2 (FOLDER)  - @user (FOLDER)

        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)

        group_user1 = create_group_user_for(@user, user2, group1)
        group_user2 = create_group_user_for(user2, @user, group2, GroupUser::FOLDER)

        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        doc = Document.first

        doc.standard_document.standard_folder_standard_documents.each do |sfsd|
          expect(UserFolderSetting.where(user_id: user2, standard_base_document_id: sfsd.standard_folder_id).count).to eq(0)
        end

        put :update_owners, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id,
          document_owners: [
            { owner_id: user2.id, owner_type: 'User' }
          ]
        expect(response.status).to eq(200)

        doc.standard_document.standard_folder_standard_documents.each do |sfsd|
          # Since @user1 is also owner and connected to user2
          # There should be 2 permissions.
          # user2 -> user2
          # user2 -> user2's group_user for @user1
          expect(UserFolderSetting.where(user_id: user2, standard_base_document_id: sfsd.standard_folder_id).count).to eq(2)
        end
      end

      it 'should set standard document visible for new owners with FLAT structure' do
        # Connection setup
        #   User1           User2
        # ------------------------
        # - user2 (FOLDER)  - @user (FLAT)

        standard_group = FactoryGirl.create(:standard_group)
        user2 = FactoryGirl.create(:consumer)

        group1 = FactoryGirl.create(:group, owner_id: @user.id, standard_group: standard_group)
        group2 = FactoryGirl.create(:group, owner_id: user2.id, standard_group: standard_group)

        group_user1 = create_group_user_for(@user, user2, group1)
        group_user2 = create_group_user_for(user2, @user, group2, GroupUser::FLAT)

        sbd = create_custom_standard_folder_standard_document(@user)

        post :create, format: :json,
          document: {
            standard_document_id: sbd.id,
          },
            document_owners: [
              { owner_id: @user.id, owner_type: 'User' }
            ],
          password_hash: @hsh,
          device_uuid: @device.device_uuid

        expect(response.status).to eq(200)
        expect(Document.count).to eq(1)

        doc = Document.first

        expect(UserFolderSetting.where(user_id: user2, standard_base_document_id: doc.standard_document_id).count).to eq(0)

        put :update_owners, format: :json, password_hash: @hsh, device_uuid: @device.device_uuid, id: doc.id,
          document_owners: [
            { owner_id: user2.id, owner_type: 'User' }
          ]
        expect(response.status).to eq(200)

        # only one folder setting will be generated for standard_document in user2's app
        # this due use2 is current user and structure type is FOLDER
        expect(UserFolderSetting.where(user_id: user2, standard_base_document_id: doc.standard_document_id).count).to eq(1)
        doc.standard_document.standard_folder_standard_documents.each do |sfsd|
          expect(UserFolderSetting.where(user_id: user2, standard_base_document_id: sfsd.standard_folder_id).count).to eq(1)
        end
      end
    end

  end
end

def create_standard_document(user, owners_list=[])
  sbd = FactoryGirl.create(:standard_document, :with_standard_folder)
  owners_list = owners_list.blank? ? [user] : owners_list
  setup_permissions(sbd, user, owners_list)
  sbd
end

def setup_permissions(standard_base_document, user, owners_list=[])
  Permission::VALUES.each do |value|
    owners_list.each do |owner|
      if owner.is_a?(GroupUser)
        next unless user.group_users_as_group_owner.where(id: owner.id).exists?
      elsif owner.is_a?(Client)
        next unless user.clients_as_advisor.where(id: owner.id).exists?
      end
      folder_structure_owner = owner
      next if standard_base_document.permissions.where(user: user, folder_structure_owner: folder_structure_owner, value: value).exists?
      standard_base_document.permissions.create!(user: user, folder_structure_owner: folder_structure_owner, value: value)
    end
  end
end

def create_custom_standard_folder_standard_document(owner)
  sf = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user)
  sf.owners.build(owner: owner)
  sf.save!
  setup_permissions(sf, @user, [owner])
  sd = StandardDocument.new(name: 'My Custom Doc', consumer_id: @user.id)
  sd.owners.build(owner: owner)
  sd.save!
  setup_permissions(sd, @user, [owner])
  sfsd = sf.standard_folder_standard_documents.new(standard_base_document_id: sd.id).save!
  sd
end

def create_group_user_for(group_owner, user=nil, group=nil, structure_type=GroupUser::FOLDER)
  group = FactoryGirl.create(:group, owner_id: group_owner.id) unless group
  group_user = FactoryGirl.create(:group_user_custom_consumer, user: user, group: group, structure_type: structure_type)
  group_user
end

def get_first_document_and_standard_document
  document = Document.first
  standard_document = document.standard_document
  standard_folder = standard_document.standard_folder_standard_documents.first.standard_folder

  return document, standard_document, standard_folder
end
