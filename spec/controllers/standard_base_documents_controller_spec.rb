require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe StandardBaseDocumentsController, type: :controller do
  before(:each) do
    load_standard_documents
    load_docyt_support
    setup_logged_in_consumer
    load_startup_keys
  end

  context "#create" do

    it 'should create customer document types' do
      standard_folder = StandardFolder.first
      post :create, :format => :json, :standard_base_document => { :name => "My Custom Receipts", :standard_folder_id => standard_folder.id }, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      res_json = JSON.parse(response.body)
      expect(StandardBaseDocument.where(:name => "My Custom Receipts").first).not_to eq(nil)
    end

    it 'should inherit with_pages value from standard folder when value is false' do
      standard_folder = StandardFolder.create(name: 'My Custom Category', description: 'Custom Category', with_pages: false, created_by: @user)
      standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::DELETE)
      standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::WRITE)
      standard_folder.owners.build(owner: @user)
      standard_folder.save!

      post :create, :format => :json, :standard_base_document => { :name => "My Custom Receipts", :standard_folder_id => standard_folder.id }, :device_uuid => @device.device_uuid

      expect(response.status).to eq(200)
      res_json = JSON.parse(response.body)
      standard_document = StandardBaseDocument.where(:name => "My Custom Receipts").first
      expect(standard_document).not_to eq(nil)
      expect(standard_document.with_pages).to eq(false)
    end

    it 'should inherit with_pages value from standard folder when value is true' do
      standard_folder = StandardFolder.create(name: 'My Custom Category', description: 'Custom Category', with_pages: true, created_by: @user)
      standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::DELETE)
      standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::WRITE)
      standard_folder.owners.build(owner: @user)
      standard_folder.save!

      post :create, :format => :json, :standard_base_document => { :name => "My Custom Receipts", :standard_folder_id => standard_folder.id }, :device_uuid => @device.device_uuid

      expect(response.status).to eq(200)
      res_json = JSON.parse(response.body)
      standard_document = StandardBaseDocument.where(:name => "My Custom Receipts").first
      expect(standard_document).not_to eq(nil)
      expect(standard_document.with_pages).to eq(true)
    end

    it 'should allow creating a custom document type for a member in your group that has nil user_id'
    it 'should not allow creating a custom document type for a member that is not your group'
    it 'should not allow creating a custom document type for a member in your group with non-nil user_id if user_access permission is not given'
    it 'should allow creating a custom document type for a member in your group with non-nil user_id if user_access permission is given'

    context "folder settings" do
      it 'should set standard folder visible for new owners'
    end

  end

  context "#destroy" do

    it 'should not destroy if not empty'

    context "permissions" do

      it 'should require folder structure owner param'
      it 'should require DELETE permission'
      it 'should just remove owner if there are still owners left'
      it 'should just remove owner if last owner'
      it 'should allow destroying a custom document type for a member in your group that has nil user_id'
      it 'should not allow destroying a custom document type for a member in your group that has non-nil user_id if user_access permission is not given'
      it 'should allow destroying a custom document type for a member in your group that has non-nil user_id if user_access permission is given'

    end

  end

end
