require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Document, :type => :model do
  before(:each) do
    load_standard_documents('standard_base_documents_structure1.json')
    load_docyt_support('standard_base_documents_structure1.json')
    @consumer = FactoryGirl.create(:consumer, :email => 'sid@vayuum.com', :pin => '123456', :pin_confirmation => '123456')
    consumer_pin = '123456'

    @consumer_password_hash = @consumer.password_hash(consumer_pin)
    Rails.stub(:user_password_hash) { @consumer_password_hash }
    Rails.stub(:app_type) { User::MOBILE_APP }

    @vayuum_password_hash = '1234567890'
    @vayuum_private_key = File.read('spec/data/id_rsa.test-startup.vayuum.pem')
    load_startup_keys({ :password_hash => @vayuum_password_hash, :private_key => @vayuum_private_key })
  end

  it { expect(subject).to belong_to(:cloud_service_authorization) }

  it 'should not create a symmetric key for system when document is created' do
    document = FactoryGirl.create(:document, :with_uploader_and_owner)
    expect(document.symmetric_keys.for_user_access(nil).count).to eq(0)
  end

  it 'should create a symmetric key for group owner along with group_user when Advisor uploads a document for a contact of the client' do
  end

  it 'should create 2 symmetric keys - one for the user himself and one for Vayuum (a placeholder key) when the document is created as belongs to another existing user in group' do
    encrypt = S3::DataEncryption.new
    other_user_pin = '123456'
    other_user = FactoryGirl.create(:consumer, :email => 'sugam@vayuum.com', :pin => other_user_pin, :pin_confirmation => other_user_pin)
    group_user = FactoryGirl.create(:group_user, :user => other_user, :group => FactoryGirl.create(:group, :owner => FactoryGirl.create(:consumer)))
    group_user2 = FactoryGirl.create(:group_user, :group => group_user.group, :user_id => @consumer.id)

    S3::DataEncryption.stub(:new) { encrypt }
    document_owner = FactoryGirl.build(:document_owner, :owner => group_user)
    document = FactoryGirl.create(:document, :consumer_id => @consumer.id, :document_owners => [document_owner], :cloud_service_full_path => nil)
    allow(S3::DataEncryption).to receive(:new).and_call_original

    expect(document.symmetric_keys.count).to eq(2) # 2 users
    my_key = document.symmetric_keys.for_user_access(@consumer.id).first
    other_users_key = document.symmetric_keys.for_user_access(group_user.user_id).first
    expect(my_key).not_to eq(nil)
    expect(other_users_key).not_to eq(nil)

    pgp = Encryption::Pgp.new({ :password => @consumer_password_hash, :private_key => @consumer.private_key })
    expect(pgp.decrypt(my_key.key_encrypted)).to eq(encrypt.encryption_key)

    pgp = Encryption::Pgp.new({ :password => other_user.password_hash(other_user_pin), :private_key => other_user.private_key })
    expect(pgp.decrypt(other_users_key.key_encrypted)).to eq(encrypt.encryption_key)
  end

  it 'should create just one symmetric key for the user himself when the document belongs to another user who is not registered in the system yet' do
    encrypt = S3::DataEncryption.new
    group_user = FactoryGirl.create(:group_user, :user => nil, :email => nil, :phone => nil, :group => FactoryGirl.create(:group, :owner => FactoryGirl.create(:consumer)))
    group_user2 = FactoryGirl.create(:group_user, :group => group_user.group, :user_id => @consumer.id)

    S3::DataEncryption.stub(:new) { encrypt }
    document_owner = FactoryGirl.build(:document_owner, :owner => group_user)
    document = FactoryGirl.create(:document, :consumer_id => @consumer.id, :document_owners => [document_owner], :cloud_service_full_path => nil)
    allow(S3::DataEncryption).to receive(:new).and_call_original
    expect(document.symmetric_keys.count).to eq(1) # 1 user
    my_key = document.symmetric_keys.for_user_access(@consumer.id).first
    expect(my_key).not_to eq(nil)

    pgp = Encryption::Pgp.new({ :password => @consumer_password_hash, :private_key => @consumer.private_key })
    expect(pgp.decrypt(my_key.key_encrypted)).to eq(encrypt.encryption_key)
  end

  it 'should remove access for document owners via update_with_owners' do
    encrypt = S3::DataEncryption.new

    group_user = FactoryGirl.create(:group_user, :email => nil, :phone => nil, :group => FactoryGirl.create(:group, :owner => FactoryGirl.create(:consumer)))
    group_user2 = FactoryGirl.create(:group_user, :group => group_user.group, :user_id => @consumer.id)
    group_user3 = FactoryGirl.create(:group_user, :group => group_user.group)

    S3::DataEncryption.stub(:new) { encrypt }
    document_owner = FactoryGirl.build(:document_owner, :owner => group_user.user)
    document_owner3 = FactoryGirl.build(:document_owner, :owner => group_user3.user)
    document = FactoryGirl.create(:document, :standard_document_id => StandardDocument.first.id, :consumer_id => @consumer.id, :document_owners => [document_owner, document_owner3], :cloud_service_full_path => nil)
    allow(S3::DataEncryption).to receive(:new).and_call_original
    expect(document.symmetric_keys.count).to eq(3) # 3 users
    my_key = document.symmetric_keys.for_user_access(@consumer.id).first
    expect(my_key).not_to eq(nil)
    document.update_with_owners(group_user.user, { }, [{ "owner_type" => "User", "owner_id" => @consumer.id }])
    expect(document.symmetric_keys.for_user_access(@consumer.id).first).not_to eq(nil)
    expect(document.symmetric_keys.for_user_access(group_user.user_id).first).not_to eq(nil)
    expect(document.symmetric_keys.for_user_access(group_user3.user).first).to eq(nil)

    expect(document.document_owners.count).to eq(1)
    expect(document.document_owners.first.owner_id).to eq(@consumer.id)
    expect(document.document_owners.first.owner_type).to eq('User')
  end

  it 'should be editable if user is owner' do
  end

  it 'shoudl be editable if user is not the owner but has an un-connected user as owner' do
  end

  it 'should be editable if user is uploader and has access to document' do
  end

  it 'should not be editable if user is uploader but now has no access' do
  end

  it 'should be editable if user is not the owner but is Manager (has UserAccess) of another user account' do
  end

  it 'should be editable if user is not the owner but is Manager (has UserAccess) of another user account who has an unconnected user as owner of the document' do
  end

  describe "Document Permission" do
    let(:document) { FactoryGirl.build(:document, consumer_id: @consumer.id) }
    let!(:consumer2) { create(:consumer, :email => 'tedi@docyt.com', :pin => '123456', :pin_confirmation => '123456') }
    let!(:owner_permissions_count) { DocumentPermission.permission_types_for(DocumentPermission::OWNER).count }
    let!(:custodian_permissions_count) { DocumentPermission.permission_types_for(DocumentPermission::CUSTODIAN).count }

    it 'should generate permissions for single user when uploader and owner is the same user' do
      document.document_owners.build(owner: @consumer)
      document.save

      expect(document.document_permissions.pluck(:user_id).uniq.first).to eq(@consumer.id)
      expect(document.document_permissions.pluck(:user_id).uniq.count).to eq(1)
      expect(document.document_permissions.count).to eq(owner_permissions_count)
    end

    it 'should regenerate permissions for uploader when uploader updated with different user' do
      document.document_owners.build(owner: @consumer)
      document.save

      document.reload
      document.consumer_id = consumer2.id
      document.save

      expect(document.reload.document_permissions.pluck(:user_id).uniq.count).to eq(2)
    end

    it 'should generate permissions for connected document owners' do
      document.document_owners.build(owner: @consumer)
      document.document_owners.build(owner: consumer2)
      document.save

      expect(document.document_permissions.pluck(:user_id).uniq.count).to eq(2)
      expect(document.document_permissions.pluck(:user_id).count).to eq(owner_permissions_count*2)
    end

    it 'should generate custodian permissions for non-connected owner ' do
      group = FactoryGirl.create(:group, owner: @consumer)
      group_user = FactoryGirl.create(:group_user, group: group, user: nil)

      document.document_owners.build(owner: group_user)
      document.save

      expect(document.document_permissions.pluck(:user_id).uniq.count).to eq(1)
      expect(document.document_permissions.pluck(:user_type)).to include('CUSTODIAN')

      permissions_list = document.document_permissions.for_user_id(@consumer.id).pluck(:value)

      expect(permissions_list).to include('VIEW')
      expect(permissions_list).to include('EDIT')
      expect(permissions_list).to include('SHARE')
      expect(permissions_list).to include('DELETE')
      expect(permissions_list).to include('EDIT_OWNER')
    end

    it 'should generate uploader permissions for uploader that is not owner' do
      document.document_owners.build(owner: consumer2)
      document.save

      expect(document.document_permissions.pluck(:user_id).uniq.count).to eq(2)
      expect(document.document_permissions.for_user_id(@consumer.id).pluck(:user_type)).to include('UPLOADER')
    end

    it 'should generate share permissions for sharee' do
      document.document_owners.build(owner: @consumer)
      document.save

      Rails.stub(:app_type) { User::MOBILE_APP }
      Rails.stub(:user_password_hash) { @consumer.password_hash("123456") }

      document.share_with(with_user_id: consumer2.id, by_user_id: @consumer.id)

      expect(document.document_permissions.pluck(:user_id).uniq.count).to eq(2)

      permissions_list = document.document_permissions.for_user_id(consumer2.id).pluck(:value)

      expect(permissions_list).to include('VIEW')
      expect(permissions_list).not_to include('EDIT')
      expect(permissions_list).not_to include('SHARE')
      expect(permissions_list).not_to include('DELETE')
      expect(permissions_list).not_to include('EDIT_OWNER')
    end

    it 'should generate correct permissions for uploader' do
      document.document_owners.build(owner: consumer2)
      document.save

      permissions_list = document.document_permissions.for_user_id(@consumer.id).pluck(:value)

      expect(permissions_list).to include('VIEW')
      expect(permissions_list).to include('EDIT')
      expect(permissions_list).to include('SHARE')
      expect(permissions_list).to include('DELETE')
      expect(permissions_list).to include('EDIT_OWNER')
    end

    it 'should generate correct permissions for owner' do
      document.document_owners.build(owner: consumer2)
      document.save

      permissions_list = document.document_permissions.for_user_id(consumer2.id).pluck(:value)

      expect(permissions_list).to include('VIEW')
      expect(permissions_list).to include('EDIT')
      expect(permissions_list).to include('SHARE')
      expect(permissions_list).to include('DELETE')
      expect(permissions_list).to include('EDIT_OWNER')
    end

    # when owner removed, he expected to become sharee
    it 'should update permissions for user when removed from owner' do
      document.document_owners.build(owner: @consumer)
      document.document_owners.build(owner: consumer2)
      document.save

      permissions_list = document.document_permissions.for_user_id(consumer2.id).pluck(:value)

      expect(permissions_list).to include('VIEW')
      expect(permissions_list).to include('EDIT')
      expect(permissions_list).to include('SHARE')
      expect(permissions_list).to include('DELETE')
      expect(permissions_list).to include('EDIT_OWNER')

      document.document_owners.where(owner: consumer2).destroy_all
      document.reload

      permissions_list = document.document_permissions.for_user_id(consumer2.id).pluck(:value)

      expect(permissions_list).to include('VIEW')
      expect(permissions_list).not_to include('EDIT')
      expect(permissions_list).not_to include('SHARE')
      expect(permissions_list).not_to include('DELETE')
      expect(permissions_list).not_to include('EDIT_OWNER')
    end

    it 'should remove permissions from share after revoked' do
      document.document_owners.build(owner: @consumer)
      document.save

      Rails.stub(:app_type) { User::MOBILE_APP }
      Rails.stub(:user_password_hash) { @consumer.password_hash("123456") }

      document.share_with(with_user_id: consumer2.id, by_user_id: @consumer.id)
      document.revoke_sharing(with_user_id: consumer2)

      permissions_list = document.document_permissions.for_user_id(consumer2.id).pluck(:value)

      expect(permissions_list.blank?).to eq(true)
    end
  end

  describe "State machine" do
    let(:document) { create(:document, :with_uploader_and_owner) }

    it 'should contain all needed states' do
      document_states = Document.aasm.states_for_select.flatten
      expect(document_states).to include(
        'pending', 'uploading', 'uploaded', 'converting', 'converted'
      )
    end

    it 'should be able to go to :uploading state only from initial state' do
      expect(document).to allow_event(:start_upload)
      expect(document).to allow_transition_to(:uploading)

      expect(document).to_not allow_event(:complete_upload)
      expect(document).to_not allow_transition_to(:uploaded)

      expect(document).to_not allow_event(:start_convertation)
      expect(document).to_not allow_transition_to(:converting)

      expect(document).to_not allow_event(:complete_convertation)
      expect(document).to_not allow_transition_to(:converted)
    end

    it 'should be allowed to go to :uploaded from initial state if s3 object exists' do
      allow_any_instance_of(Document).to receive(:s3_object_exists?).and_return(true)

      expect(document).to allow_event(:complete_upload)
      expect(document).to allow_transition_to(:uploaded)
    end

    it 'should be allowed to go to :uploaded from :uploading state if s3 object exists' do
      allow_any_instance_of(Document).to receive(:s3_object_exists?).and_return(true)
      document.update(state: 'uploading')

      expect(document).to allow_event(:complete_upload)
      expect(document).to allow_transition_to(:uploaded)
    end

    it 'should be allowed to go to :converting from :uploaded state only' do
      document.update(state: 'uploaded')

      expect(document).to allow_event(:start_convertation)
      expect(document).to allow_transition_to(:converting)
    end

    it 'should be allowed to go to :uploading from :converting state only' do
      document.update(state: 'converting')

      expect(document).to allow_event(:start_upload)
      expect(document).to allow_transition_to(:uploading)
    end

    it 'should be allowed to go to :converted from :converting state only' do
      document.update(state: 'converting')

      expect(document).to allow_event(:complete_convertation)
      expect(document).to allow_transition_to(:converted)
    end
  end

  context 'Associations' do
    it { is_expected.to have_many(:faxes).dependent(:nullify) }
    it { is_expected.to have_many(:workflow_document_uploads).dependent(:destroy) }
    it { is_expected.to have_many(:document_preparers).dependent(:destroy) }
  end

  context '#convert_document_to_img_or_flatten' do
    let!(:document) {
      build(:document, :specific_extension,
        source: 'WebChat',
        state: 'uploaded',
        original_file_name: "#{Faker::Lorem.word}.jpg",
      )
    }

    context 'convert microsoft file to pdf job' do
      it 'should call' do
        document.file_content_type = "application/msword"
        document.save

        expect(ConvertMicrosoftFileToPdfJob).to receive(:perform_later).with(document.id)
        document.start_convertation
      end

      it 'should call' do
        document.file_content_type = "application/vnd.ms-excel"
        document.save

        expect(ConvertMicrosoftFileToPdfJob).to receive(:perform_later).with(document.id)
        document.start_convertation
      end

      it 'should call' do
        document.file_content_type = "application/vnd.ms-powerpoint"
        document.save

        expect(ConvertMicrosoftFileToPdfJob).to receive(:perform_later).with(document.id)
        document.start_convertation
      end

      it 'should call' do
        document.file_content_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        document.save

        expect(ConvertMicrosoftFileToPdfJob).to receive(:perform_later).with(document.id)
        document.start_convertation
      end

      it 'should not called' do
        document.file_content_type = Faker::Name.name
        document.save

        expect(ConvertDocumentImgToPdfJob).to_not receive(:perform_later).with(document.id)
        expect(ConvertDocumentPdfToImgJob).to_not receive(:perform_later).with(document.id)
        expect(ConvertMicrosoftFileToPdfJob).to_not receive(:perform_later).with(document.id)
        document.start_convertation
      end
    end

    context 'convert document image to pdf job' do
      it 'should call' do
        document.file_content_type = "image/jpeg"
        document.save

        expect(ConvertDocumentImgToPdfJob).to receive(:perform_later).with(document.id)
        document.start_convertation
      end

      it 'should call' do
        document.file_content_type = "image/png"
        document.save

        expect(ConvertDocumentImgToPdfJob).to receive(:perform_later).with(document.id)
        document.start_convertation
      end

      it 'should call' do
        document.file_content_type = "image/gif"
        document.save

        expect(ConvertDocumentImgToPdfJob).to receive(:perform_later).with(document.id)
        document.start_convertation
      end

      it 'should not called' do
        document.file_content_type = Faker::Name.name
        document.save

        expect(ConvertDocumentImgToPdfJob).to_not receive(:perform_later).with(document.id)
        document.start_convertation
      end
    end

    context 'convert document pdf to image job' do
      it 'should call FlattenPdfJob if document from WebChat' do
        document.file_content_type = "application/pdf"
        document.source = 'WebChat'
        document.save

        expect(FlattenPdfJob).to receive(:perform_later).with(document.id)
        document.start_convertation
      end

      it 'should call ConvertDocumentPdfToImgJob if document not from WebChat' do
        document.file_content_type = "application/pdf"
        document.source = Faker::Name.name
        document.save

        expect(ConvertDocumentPdfToImgJob).to receive(:perform_later).with(document.id)
        document.start_convertation
      end

      it 'should called SlackHelper if document is incorrect' do
        document.file_content_type = Faker::Name.name
        document.save

        expect(SlackHelper).to receive(:ping).once
        document.start_convertation
      end
    end
  end

end
