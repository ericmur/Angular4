require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe DocumentFieldValuesController, type: :controller do

  describe "create and update document field value" do
    def load_standard_document_fields
      @standard_document_with_fields = StandardDocument.where(:name => 'Drivers License').first
      @standard_document_field = @standard_document_with_fields.standard_document_fields.create!(:name => 'Drivers License Number', :data_type => 'int', :field_id => 5)
    end

    before(:each) do
      load_standard_documents
      load_standard_document_fields
      load_docyt_support
      setup_logged_in_consumer
      load_startup_keys
    end

    it 'should create document field values' do
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      doc = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [doc_owner])

      field_id = @standard_document_field.field_id
      post :create, :format => :json, :document_field_value => { :input_value => "123456", :document_id => doc.id, :local_standard_document_field_id => field_id }, :password_hash => @hsh, :device_uuid => @device.device_uuid

      expect(response.status).to eq(200)
      res_json = JSON.parse(response.body)
    end

    it 'should update document field value' do
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      doc = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [doc_owner])
      Rails.stub(:user_password_hash) { @hsh }
      field_value = FactoryGirl.create(:document_field_value, :document => doc, :local_standard_document_field_id => @standard_document_field.field_id, :input_value => '123456', :user_id => @user.id)

      put :update, :format => :json, :id => field_value.id, :document_field_value => { :input_value => "7890" }, :password_hash => @hsh, :device_uuid => @device.device_uuid

      expect(response.status).to eq(200)
      res_json = JSON.parse(response.body)
      field_value.reload
      expect(field_value.value).to eq("7890")
    end

    it 'should not allow me to update field value of a document I dont have perms to edit' do
    end

    it 'should not allow me to create field value of a document I dont have perms to edit' do
    end

  end

  describe "document field value expiry check" do
    def load_standard_document_fields
      @standard_document_with_fields = StandardDocument.where(:name => 'Drivers License').first
      @standard_document_field = @standard_document_with_fields.standard_document_fields.create!(:name => 'Expiry Date', :data_type => 'expiry_date', :field_id => 5, notify: true, min_year: -1, max_year: 1)
      @standard_document_field.notify_durations.create!(amount: 1, unit: 'day')
    end

    before(:each) do
      load_standard_documents
      load_standard_document_fields
      load_docyt_support
      setup_logged_in_consumer
      load_startup_keys
    end

    it "should expire document when creating field with expired date" do
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      doc = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [doc_owner])
      Rails.stub(:user_password_hash) { @hsh }

      input_value = Time.zone.now.to_date.strftime("%m/%d/%Y")
      field_id = @standard_document_field.field_id
      post :create, :format => :json, :document_field_value => { :input_value => input_value, :document_id => doc.id, :local_standard_document_field_id => field_id }, :password_hash => @hsh, :device_uuid => @device.device_uuid

      doc.reload
      field = doc.document_field_values.first
      expect(field.notification_level).to eq(NotifyDuration::EXPIRED)

      expect(response.status).to eq(200)
      res_json = JSON.parse(response.body)
    end

    it 'should increase document notification level if field value has expire' do
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      doc = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [doc_owner])
      Rails.stub(:user_password_hash) { @hsh }

      input_value = (Time.zone.now.to_date + 1.day).strftime("%m/%d/%Y")
      field_value = FactoryGirl.create(:document_field_value, :document => doc, :local_standard_document_field_id => @standard_document_field.field_id, :input_value => input_value, :user_id => @user.id)

      doc.reload
      field = doc.document_field_values.first
      expect(field.notification_level).to eq(0)

      update_input_value = (Time.zone.now.to_date).strftime("%m/%d/%Y")
      put :update, :format => :json, :id => field_value.id, :document_field_value => { :input_value => update_input_value }, :password_hash => @hsh, :device_uuid => @device.device_uuid

      expect(response.status).to eq(200)
      res_json = JSON.parse(response.body)
      field_value.reload
      expect(field_value.value).to eq(update_input_value)

      expect(field_value.notification_level).to eq(NotifyDuration::EXPIRED)
    end
  end

  describe "document field value expiry check for multiple durations" do
    def load_standard_document_fields
      @standard_document_with_fields = StandardDocument.where(:name => 'Drivers License').first
      @standard_document_field = @standard_document_with_fields.standard_document_fields.create!(:name => 'Expiry Date', :data_type => 'expiry_date', :field_id => 5, notify: true, min_year: -1, max_year: 1)
      @standard_document_field.notify_durations.create!(amount: 1, unit: 'day')
      @standard_document_field.notify_durations.create!(amount: 3, unit: 'months')
      @standard_document_field.notify_durations.create!(amount: 6, unit: 'months')
    end

    def run_create_and_update(expire_date)
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      doc = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [doc_owner])
      Rails.stub(:user_password_hash) { @hsh }

      input_value = (Time.zone.now.to_date + 1.day).strftime("%m/%d/%Y")
      field_value = FactoryGirl.create(:document_field_value, :document => doc, :local_standard_document_field_id => @standard_document_field.field_id, :input_value => input_value, :user_id => @user.id)

      expect(field_value.notification_level).to eq(0)

      update_input_value = (expire_date).strftime("%m/%d/%Y")
      put :update, :format => :json, :id => field_value.id, :document_field_value => { :input_value => update_input_value }, :password_hash => @hsh, :device_uuid => @device.device_uuid

      doc.reload
    end

    before(:each) do
      load_standard_documents
      load_standard_document_fields
      load_docyt_support
      setup_logged_in_consumer
      load_startup_keys
    end

    # should say not expired since we only have schedule for 3 months from now, so it will not get caught
    it 'should not expired when expire date is set 2 months from now' do
      doc = run_create_and_update(Time.zone.now.to_date + 2.months)
      field = doc.document_field_values.first
      expect(field.notification_level).to eq(NotifyDuration::NONE)
    end

    it 'should say about to expire when expire date is set 3 months from now' do
      doc = run_create_and_update(Time.zone.now.to_date + 3.months)
      field = doc.document_field_values.first
      expect(field.notification_level).to eq(NotifyDuration::EXPIRING)
    end

    it 'should say about to expire when expire date is set 1 day from now' do
      doc = run_create_and_update(Time.zone.now.to_date + 1.day)
      field = doc.document_field_values.first
      expect(field.notification_level).to eq(NotifyDuration::EXPIRING)
    end

    it 'should not expired when expire date is set 7 months from now' do
      doc = run_create_and_update(Time.zone.now.to_date + 7.months)
      field = doc.document_field_values.first
      expect(field.notification_level).to eq(NotifyDuration::NONE)
    end

    it 'should say about to expire when expire date is set 6 months from now' do
      doc = run_create_and_update(Time.zone.now.to_date + 6.months)
      field = doc.document_field_values.first
      expect(field.notification_level).to eq(NotifyDuration::EXPIRING)
    end

    it "should say expired when less one month from today" do
      doc = run_create_and_update(Time.zone.now.to_date - 1.month)
      field = doc.document_field_values.first
      expect(field.notification_level).to eq(NotifyDuration::EXPIRED)
    end

    it "should say expired in today" do
      doc = run_create_and_update(Time.zone.now.to_date)
      field = doc.document_field_values.first
      expect(field.notification_level).to eq(NotifyDuration::EXPIRED)
    end
  end

  describe "saving document field value with encryption" do
    def load_standard_document_fields
      @standard_document_with_fields = StandardDocument.where(:name => 'Drivers License').first
      @standard_document_field = @standard_document_with_fields.standard_document_fields.create!(:name => 'Drivers License Number', :data_type => 'int', :field_id => 5, encryption: true)
    end

    before(:each) do
      load_standard_documents
      load_standard_document_fields
      load_docyt_support
      setup_logged_in_consumer
      load_startup_keys
    end

    it 'should update with encrypted value' do
      doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
      doc = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [doc_owner])
      Rails.stub(:user_password_hash) { @hsh }
      field_value = FactoryGirl.create(:document_field_value, :document => doc, :local_standard_document_field_id => @standard_document_field.field_id, :input_value => '123456', :user_id => @user.id)

      put :update, :format => :json, :id => field_value.id, :document_field_value => { :input_value => "7890" }, :password_hash => @hsh, :device_uuid => @device.device_uuid

      expect(response.status).to eq(200)
      res_json = JSON.parse(response.body)
      field_value.reload
      expect(field_value.decrypt_value).to eq("7890")
      expect(field_value.value).to eq(nil)
    end
  end

  context "#create" do

    def load_standard_document_fields
      @standard_document_with_fields = StandardDocument.where(:name => 'Drivers License').first
      @standard_document_field = @standard_document_with_fields.standard_document_fields.create!(:name => 'Drivers License Number', :data_type => 'int', :field_id => 5)
    end

    before(:each) do
      load_standard_documents
      load_standard_document_fields
      load_docyt_support
      setup_logged_in_consumer
      load_startup_keys
    end


    context "document cache service" do

      def execute_document_field_value_create
        field_id = @standard_document_field.field_id
        post :create, :format => :json, :document_field_value => { :input_value => "123456", :document_id => @doc.id, :local_standard_document_field_id => field_id }, :password_hash => @hsh, :device_uuid => @device.device_uuid

        expect(response.status).to eq(200)
      end

      before(:each) do
        @doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
        @doc = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [@doc_owner])
      end

      it 'should successfully enqueue document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], any_args).and_call_original

        execute_document_field_value_create
      end

      it 'should update owners and uploader document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], [@user.id]).and_call_original

        execute_document_field_value_create
      end
    end
  end

  context "#update" do
    def load_standard_document_fields
      @standard_document_with_fields = StandardDocument.where(:name => 'Drivers License').first
      @standard_document_field = @standard_document_with_fields.standard_document_fields.create!(:name => 'Drivers License Number', :data_type => 'int', :field_id => 5)
    end

    before(:each) do
      load_standard_documents
      load_standard_document_fields
      load_docyt_support
      setup_logged_in_consumer
      load_startup_keys
    end

    context "document cache service" do
      def execute_document_field_value_update
        put :update, :format => :json, :id => @field_value.id, :document_field_value => { :input_value => "7890" }, :password_hash => @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end

      before(:each) do
        @doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
        @doc = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [@doc_owner])
        Rails.stub(:user_password_hash) { @hsh }
        @field_value = FactoryGirl.create(:document_field_value, :document => @doc, :local_standard_document_field_id => @standard_document_field.field_id, :input_value => '123456', :user_id => @user.id)
      end

      it 'should successfully enqueue document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], any_args).and_call_original

        execute_document_field_value_update
      end

      it 'should update owners and uploader document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], [@user.id]).and_call_original

        execute_document_field_value_update
      end
    end
  end

  context "#destroy" do
    def load_standard_document_fields
      @standard_document_with_fields = StandardDocument.where(:name => 'Drivers License').first
      @standard_document_field = @standard_document_with_fields.standard_document_fields.create!(:name => 'Drivers License Number', :data_type => 'int', :field_id => 5)
    end

    before(:each) do
      load_standard_documents
      load_standard_document_fields
      load_docyt_support
      setup_logged_in_consumer
      load_startup_keys
    end

    context "document cache service" do
      def execute_document_field_value_delete
        put :destroy, :format => :json, :id => @field_value.id, :password_hash => @hsh, :device_uuid => @device.device_uuid
        expect(response.status).to eq(200)
      end

      before(:each) do
        @doc_owner = FactoryGirl.build(:document_owner, :owner => @user)
        @doc = FactoryGirl.create(:document, :uploader => @user, :standard_document => @standard_document_with_fields, :document_owners => [@doc_owner])
        Rails.stub(:user_password_hash) { @hsh }
        @field_value = FactoryGirl.create(:document_field_value, :document => @doc, :local_standard_document_field_id => @standard_document_field.field_id, :input_value => '123456', :user_id => @user.id)
      end

      it 'should successfully enqueue document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], any_args).and_call_original

        execute_document_field_value_delete
      end

      it 'should update owners and uploader document cache' do
        expect(DocumentCacheService).to receive(:update_cache).with([:document], [@user.id]).and_call_original

        execute_document_field_value_delete
      end
    end
  end

end
