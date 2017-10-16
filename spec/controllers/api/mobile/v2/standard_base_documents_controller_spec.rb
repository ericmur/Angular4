require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

describe Api::Mobile::V2::StandardBaseDocumentsController do
  before(:each) do
    load_standard_documents
    stub_docyt_support_creation
    setup_logged_in_consumer
    load_startup_keys

    create(:standard_category)
  end

  context "#set_hidden" do
    it 'should able to hide category' do
      @standard_folder = StandardFolder.first
      put :set_hidden, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
    end

    it 'should successfully update folder setting cache'
  end

  context "#set_displayed" do
    it 'should able to display category' do
      @standard_folder = StandardFolder.first
      put :set_hidden, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
      put :set_displayed, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid
      expect(response.status).to eq(200)
    end

    it 'should successfully update folder setting cache'
  end

  context "#destroy" do

    it 'should not able to destroy system folder' do
      @standard_folder = StandardFolder.first
      delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid
      expect(response.status).to eq(422)
    end

    # This is will not actually delete the StandardFolder, but instead it just remove folder_structure_owner from owners
    it 'should able to destroy owned category', focus: true do
      @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user)
      @standard_group = FactoryGirl.create(:standard_group)
      @group = FactoryGirl.create(:group, { :standard_group_id => @standard_group.id, :owner_id => @user.id })
      @group_user = FactoryGirl.create(:group_user, :group => @group, :user => nil)
      @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::DELETE)
      @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @group_user, value: Permission::DELETE)
      @standard_folder.owners.build(owner: @user)
      @standard_folder.owners.build(owner: @group_user)
      @standard_folder.save!

      delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid, folder_structure_owner_id: @user.id, folder_structure_owner_type: 'User'
      expect(response.status).to eq(200)

      @standard_folder.reload
      expect(@standard_folder.owners.count).to eq(1)
      expect(@standard_folder.owners.first.owner_id).to eq(@group_user.id)
      expect(@standard_folder.owners.first.owner_type).to eq('GroupUser')
    end

    # This is will delete the StandardFolder, because last owner has been removed
    it 'should able to destroy category owned by my non-connected group_user' do
      @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user)
      @standard_group = FactoryGirl.create(:standard_group)
      @group = FactoryGirl.create(:group, { :standard_group_id => @standard_group.id, :owner_id => @user.id })
      @group_user = FactoryGirl.create(:group_user, :group => @group, :user => nil)
      @standard_folder.owners.build(owner: @group_user)
      @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::DELETE)
      @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @group_user, value: Permission::DELETE)
      @standard_folder.save!

      expect(StandardFolder.for_owner(@user.id, 'User').count).to eq(0)

      delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid, folder_structure_owner_id: @group_user.id, folder_structure_owner_type: 'GroupUser'
      expect(response.status).to eq(200)

      expect(StandardFolder.where(id: @standard_folder.id).count).to eq(0)
    end

    # This is will not actually delete the StandardFolder, but instead it just remove folder_structure_owner from owners
    it 'should able to destroy category owned by me and other group_user' do
      @standard_group = FactoryGirl.create(:standard_group)
      @user2 = FactoryGirl.create(:consumer) #another user to share with

      @group = FactoryGirl.create(:group, { :standard_group_id => @standard_group.id, :owner_id => @user2.id })
      @group_user = FactoryGirl.create(:group_user, :group => @group, :user => nil)

      @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user2)
      @standard_folder.owners.build(owner: @user)
      @standard_folder.owners.build(owner: @group_user)
      @standard_folder.save!

      delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid, folder_structure_owner_id: @group_user.id, folder_structure_owner_type: 'GroupUser'
      expect(response.status).to eq(422)
    end

    # This is will not actually delete the StandardFolder, but instead it just remove folder_structure_owner from owners
    it 'should able to destroy category owned by me and other' do
      @user2 = FactoryGirl.create(:consumer) #another user to share with
      @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user2)
      @standard_folder.owners.build(owner: @user)
      @standard_folder.owners.build(owner: @user2)
      @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::DELETE)
      @standard_folder.save!

      delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid, folder_structure_owner_id: @user.id, folder_structure_owner_type: 'User'
      expect(response.status).to eq(200)
    end

    # Should not able to destroy because doesn't have the permission to DELETE
    it 'should not able to destroy category owned by other' do
      @user2 = FactoryGirl.create(:consumer) #another user to share with
      @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user2)
      @standard_folder.owners.build(owner: @user2)
      @standard_folder.save!

      delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid, folder_structure_owner_id: @user2.id, folder_structure_owner_type: 'User'

      expect(response.status).to eq(422)
      expect(JSON.parse(response.body)["errors"].first).to eq("You don't have the permissions to delete this category.")
    end

    it 'should just remove owner if there are still owners left' do
      @user2 = FactoryGirl.create(:consumer) #another user to share with
      @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user)
      @standard_folder.owners.build(owner: @user)
      @standard_folder.owners.build(owner: @user2)
      @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::DELETE)
      @standard_folder.save!

      expect(StandardFolder.where(id: @standard_folder.id).first.owners.count).to eq(2)

      delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid, folder_structure_owner_id: @user.id, folder_structure_owner_type: 'User'
      expect(response.status).to eq(200)

      expect(StandardFolder.where(id: @standard_folder.id).count).to eq(1)
      expect(StandardFolder.where(id: @standard_folder.id).first.owners.count).to eq(1)
    end

    it 'should just remove owner if last owner' do
      @user2 = FactoryGirl.create(:consumer) #another user to share with
      @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user)
      @standard_folder.owners.build(owner: @user)
      @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::DELETE)
      @standard_folder.save!

      expect(StandardFolder.where(id: @standard_folder.id).first.owners.count).to eq(1)

      delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid, folder_structure_owner_id: @user.id, folder_structure_owner_type: 'User'
      expect(response.status).to eq(200)

      expect(StandardFolder.where(id: @standard_folder.id).count).to eq(0)
    end

    context "permissions" do

      it 'should not destroy if not empty' do
        @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user)
        @standard_folder.owners.build(owner: @user)
        @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::DELETE)
        @standard_folder.save!

        @standard_document = StandardDocument.new(name: 'My Custom Doc', consumer_id: @user.id)
        @standard_document.owners.build(owner: @user)
        @standard_document.save!

        @standard_folder.standard_folder_standard_documents.new(standard_base_document_id: @standard_document.id).save!

        delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid, folder_structure_owner_id: @user.id, folder_structure_owner_type: 'User'
        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)["errors"].first).to eq("Selected category is not empty.")
      end

      it 'should require folder structure owner param' do
        @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user)
        @standard_folder.owners.build(owner: @user)
        @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::DELETE)
        @standard_folder.save!

        delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid

        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)["errors"].first).to eq("Sorry cannot do that.")
      end

      it 'should require DELETE permission' do
        @standard_folder = StandardFolder.new(name: 'My Custom Category', description: 'Custom Category', created_by: @user)
        @standard_folder.owners.build(owner: @user)
        @standard_folder.permissions.build(user_id: @user.id, folder_structure_owner: @user, value: Permission::VIEW)
        @standard_folder.save!

        delete :destroy, format: :json, id: @standard_folder.id, :device_uuid => @device.device_uuid

        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)["errors"].first).to eq("Sorry cannot do that.")
      end

      it 'should successfully update standard folder cache'
    end

  end

end
