require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe PagesController, :type => :controller do
  before(:each) do
    #load_standard_documents
    #load_docyt_support
    stub_docyt_support_creation
    setup_logged_in_consumer

    load_startup_keys

    Rails.stub(:user_password_hash) { @hsh }

    doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
    @document = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [doc_owner])

    FileUtils.mkdir_p TEST_WORKDIR

    Page.any_instance.stub(:s3_object_exists?).and_return(true)
  end

  after(:each) do
    FileUtils.rmdir TEST_WORKDIR
  end
  
  it 'should successfully create a page' do
    expect(@document.pages.count).to eq(0)

    post :create, format: :json, document_id: @document.id, page: { page_num: 1, name: 'test' }, password_hash: @hsh, :device_uuid => @device.device_uuid

    expect(response.status).to eq(200)
    res_json = JSON.parse(response.body)

    expect(@document.pages.count).to eq(1)

    page = @document.pages.first

    expect(res_json['page']['document_id']).to eq(@document.id)
    expect(res_json['page']['name']).to eq(page.name)
    expect(res_json['page']['page_num']).to eq(page.page_num)
    expect(res_json['page']['state']).to eq(page.state)
    expect(res_json['page']['s3_object_key']).to eq(nil)
  end

  it 'should successfully show the page' do
    page = @document.pages.new
    page.name = 'Test'
    page.page_num = 1
    page.save

    expect(@document.pages.count).to eq(1)

    get :show, format: :json, id: page.id, password_hash: @hsh, :device_uuid => @device.device_uuid
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(200)

    expect(res_json['page']['document_id']).to eq(@document.id)
    expect(res_json['page']['name']).to eq(page.name)
    expect(res_json['page']['page_num']).to eq(page.page_num)
    expect(res_json['page']['state']).to eq(page.state)
  end
  
  it 'should successfully upload to page' do
    page = @document.pages.new
    page.name = 'Test'
    page.page_num = 1
    page.save

    expect(@document.pages.count).to eq(1)

    @de_1 = S3::DataEncryption.new(@document.symmetric_keys.for_user_access(@user.id).first.decrypt_key)

    upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"
    generate_sample_file(upload_file_path)

    s3_object_key = "pages/#{page.id}/test.txt"
    original_s3_object_key = "pages/#{page.id}/test.txt"

    md5 = Encryption::MD5Digest.new
    original_file_md5 = md5.file_digest_base64(upload_file_path)
    final_file_md5 = md5.file_digest_base64(upload_file_path)
    page.original_file_md5 = original_file_md5
    page.final_file_md5 = final_file_md5
    page.save

    @de_1.upload(upload_file_path, { object_key: s3_object_key })

    put :complete_upload, format: :json, id: page.id, s3_object_key: s3_object_key, original_s3_object_key: original_s3_object_key, password_hash: @hsh, :device_uuid => @device.device_uuid, original_file_md5: original_file_md5, final_file_md5: final_file_md5

    res_json = JSON.parse(response.body)
    expect(response.status).to eq(200)

    page.reload

    expect(res_json['page']['document_id']).to eq(@document.id)
    expect(res_json['page']['name']).to eq(page.name)
    expect(res_json['page']['page_num']).to eq(page.page_num)
    expect(res_json['page']['state']).to eq(page.state)
    expect(res_json['page']['s3_object_key']).to eq(s3_object_key)
  end

  it 'should successfully update s3 keys for a page' do
    page = @document.pages.new
    page.name = 'Test'
    page.page_num = 1
    page.save

    expect(@document.pages.count).to eq(1)

    @de_1 = S3::DataEncryption.new(@document.symmetric_keys.for_user_access(@user.id).first.decrypt_key)

    upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"
    generate_sample_file(upload_file_path)

    s3_object_key = "pages/#{page.id}/test.txt"
    original_s3_object_key = "pages/#{page.id}/test.txt"

    md5 = Encryption::MD5Digest.new
    original_file_md5 = md5.file_digest_base64(upload_file_path)
    final_file_md5 = md5.file_digest_base64(upload_file_path)
    page.original_file_md5 = original_file_md5
    page.final_file_md5 = final_file_md5
    page.save

    @de_1.upload(upload_file_path, { object_key: s3_object_key })

    symm_key = page.document.symmetric_keys.for_user_access(@user.id).first

    page.encryption_key = symm_key.decrypt_key
    page.s3_object_key = s3_object_key
    page.original_s3_object_key = original_s3_object_key

    page.complete_upload!

    put :reupload, format: :json, id: page.id, password_hash: @hsh, :device_uuid => @device.device_uuid, original_file_md5: original_file_md5, final_file_md5: final_file_md5
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(200)
    page.reload
    expect(page.document.symmetric_keys.for_user_access(nil).count).to eq(0)
    expect(page.state).to eq("uploading")
    expect(page.s3_object_key).to eq(nil)
    expect(page.original_s3_object_key).to eq(nil)
    upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i + 1}.txt"
    generate_sample_file(upload_file_path)
    s3_object_key = "pages/#{page.id}/test_new.txt"
    original_s3_object_key = "pages/#{page.id}/test_original_new.txt"
    @de_1.upload(upload_file_path, { object_key: s3_object_key })

    page.reload
    expect_any_instance_of(Page).to receive(:recreate_document_pdf)
    put :complete_upload, format: :json, id: page.id, s3_object_key: s3_object_key, original_s3_object_key: original_s3_object_key, password_hash: @hsh, :device_uuid => @device.device_uuid, original_file_md5: original_file_md5, final_file_md5: final_file_md5
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(200)
    page.reload
    expect(page.document.symmetric_keys.for_user_access(nil).count).to eq(1)
    expect(page.state).to eq("uploaded")
    expect(page.s3_object_key).to eq(s3_object_key)
    expect(page.original_s3_object_key).to eq(original_s3_object_key)
  end

  it 'should destroy a page and do not recreate document pdf when it is last page' do
    page = @document.pages.new
    page.name = 'Test'
    page.page_num = 1
    page.save

    expect(@document.pages.count).to eq(1)

    # should not recreate document pdf if last page was destroyed
    expect_any_instance_of(Page).not_to receive(:recreate_document_pdf)
    delete :destroy, format: :json, id: page.id, password_hash: @hsh, :device_uuid => @device.device_uuid
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(204)
    expect(@document.pages.count).to eq(0)
  end

  it 'should destroy a page and recreate document pdf when it is not last page' do
    FactoryGirl.create_list(:page, 2, document: @document)

    expect(@document.pages.count).to eq(2)

    expect_any_instance_of(Page).to receive(:recreate_document_pdf)
    delete :destroy, format: :json, id: @document.pages.last.id, password_hash: @hsh, :device_uuid => @device.device_uuid
    res_json = JSON.parse(response.body)
    expect(response.status).to eq(204)
    expect(@document.symmetric_keys.for_user_access(nil).count).to eq(1)
    expect(@document.pages.count).to eq(1)
  end

  it 'should failed to register blank s3 object key' do
    page = @document.pages.new
    page.name = 'Test'
    page.page_num = 1
    upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"
    generate_sample_file(upload_file_path)
    md5 = Encryption::MD5Digest.new
    original_file_md5 = md5.file_digest_base64(upload_file_path)
    final_file_md5 = md5.file_digest_base64(upload_file_path)
    page.original_file_md5 = original_file_md5
    page.final_file_md5 = final_file_md5
    page.save

    expect(@document.pages.count).to eq(1)
    expect_any_instance_of(Page).not_to receive(:recreate_document_pdf)

    s3_object_key = nil

    put :complete_upload, format: :json, id: page.id, s3_object_key: s3_object_key, password_hash: @hsh, :device_uuid => @device.device_uuid, original_file_md5: original_file_md5, final_file_md5: final_file_md5

    res_json = JSON.parse(response.body)
    expect(response.status).to eq(422)

    expect(res_json['errors'].first).to include('object key can\'t be blank')

    page.reload

    expect(page.s3_object_key).to eq(nil)
    expect(page.state).to eq('pending')
  end

  it 'should fail to register invalid s3 object key' do
    page = @document.pages.new
    page.name = 'Test'
    page.page_num = 1
    upload_file_path = "#{TEST_WORKDIR}/upload#{Time.now.to_i}.txt"
    generate_sample_file(upload_file_path)
    md5 = Encryption::MD5Digest.new
    original_file_md5 = md5.file_digest_base64(upload_file_path)
    final_file_md5 = md5.file_digest_base64(upload_file_path)
    page.original_file_md5 = original_file_md5
    page.final_file_md5 = final_file_md5
    page.save

    expect(@document.pages.count).to eq(1)
    expect_any_instance_of(Page).not_to receive(:recreate_document_pdf)

    s3_object_key = 'an-invalid-object-key-example'

    put :complete_upload, format: :json, id: page.id, s3_object_key: s3_object_key, password_hash: @hsh, :device_uuid => @device.device_uuid, original_file_md5: original_file_md5, final_file_md5: final_file_md5

    res_json = JSON.parse(response.body)
    expect(response.status).to eq(422)

    expect(res_json['errors'].first).to include('object key can\'t be blank')

    page.reload

    expect(page.s3_object_key).to eq(nil)
    expect(page.state).to eq('pending')
  end

  it 'should allow reordering of pages' do
    FactoryGirl.create_list(:page, 2, document: @document)
    valid_reorder_params =
      [{
        id: @document.pages.first.id,
        n: @document.pages.first.page_num+1
      }]

    expect(@document.pages.count).to eq(2)

    expect_any_instance_of(Page).to receive(:recreate_document_pdf)
    post :reorder, password_hash: @hsh, format: :json, :pages => valid_reorder_params, :device_uuid => @device.device_uuid
    expect(response.status).to eq(200)
    expect(@document.symmetric_keys.for_user_access(nil).count).to eq(1)
    expect(@document.pages.count).to eq(2)
  end

  it 'should not allow you to create a page without checking for permissions' do
  end

  it 'should not allow you to destroy a page without checking for permissions' do
  end

  it 'should not allow you to start upload of a page without checking for permissions' do
  end

  it 'should not allow you to call complete_upload on a page without checking for permissions' do
  end

  it 'should not allow you to reorder pages without checking for permissions' do
  end

  context "#create" do
    context "document cache service" do
      it 'should successfully enqueue document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], any_args).and_call_original

        post :create, format: :json, document_id: @document.id, page: { page_num: 1, name: 'test' }, password_hash: @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end

      it 'should update owners and uploader document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], [@user.id]).and_call_original

        post :create, format: :json, document_id: @document.id, page: { page_num: 1, name: 'test' }, password_hash: @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end
    end
  end

  context "#destroy" do
    context "document cache service" do
      it 'should successfully enqueue document cache' do
        FactoryGirl.create_list(:page, 2, document: @document)

        expect(@document.pages.count).to eq(2)

        expect(DocumentCacheService).to receive(:update_cache).with([:document], any_args).and_call_original
        delete :destroy, format: :json, id: @document.pages.last.id, password_hash: @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(204)
      end

      it 'should update owners and uploader document cache' do
        FactoryGirl.create_list(:page, 2, document: @document)

        expect(@document.pages.count).to eq(2)

        expect(DocumentCacheService).to receive(:update_cache).with([:document], [@user.id]).and_call_original
        delete :destroy, format: :json, id: @document.pages.last.id, password_hash: @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(204)
      end
    end
  end

end
