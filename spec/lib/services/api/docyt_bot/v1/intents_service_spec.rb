require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::DocytBot::V1::IntentsService do
  before do
    load_standard_documents
    load_docyt_support
  end

  let!(:service)  { Api::DocytBot::V1::IntentsService }

  let!(:score)             { 0.9 }
  let!(:docyt_bot_session) { DocytBotSession.create_with_token! }

  context "get field_value response" do

    it 'should get drivers license number when queried for one' do

      #Add Drivers License doc to user.
      sf = StandardFolder.where(:name => 'Personal', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = document.standard_document.standard_document_fields.first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "E144444"
      field_value.save!

      std_field2 = document.standard_document.standard_document_fields.where(:name => 'State').first
      field_value2 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field2.field_id)
      field_value2.input_value = "CA"
      field_value2.save!

      owner = document.uploader
      field_name = "drivers license number"

      #DocytBot Request
      service.any_instance.stub(:process_intent) { { :intent => "GetDocumentFieldInfo", :score => score, :slots => { :field_name => field_name } } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me my #{field_name}", :device_type => 'DocytBot' })
      
      res = service_instance.get_response
      expect(res.count).to eq(2)
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/#{field_value.value}/) ## Match with value of Drivers License
      expect(mes[:message]).to match(/California/) ## Match with value of Drivers License
    end

    it 'should get drivers license number of spouse when queried for one and not any other drivers license of another contact' do
      #Add Drivers License doc to user.
      sf = StandardFolder.where(:name => 'Personal', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)

      owner = document.uploader
      group = FactoryGirl.create(:group, :owner_id => owner.id)
      #Add coworker for this user
      group_user = FactoryGirl.create(:group_user, :label => GroupUser::COWORKER, :group => group, :user_id => nil)
      document = FactoryGirl.build(:document, :standard_document => sbd, :consumer_id => owner.id, :document_owners => [FactoryGirl.build(:document_owner, :owner => group_user)], :cloud_service_authorization => nil)

      document.save!
      std_field = document.standard_document.standard_document_fields.first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "E14COWORKER"
      field_value.save!

      # Add spouse for this user
      group_user = FactoryGirl.create(:group_user, :label => GroupUser::SPOUSE, :group => group, :user_id => nil)
      document = FactoryGirl.build(:document, :standard_document => sbd, :consumer_id => owner.id, :document_owners => [FactoryGirl.build(:document_owner, :owner => group_user)], :cloud_service_authorization => nil)

      document.save!
      std_field = document.standard_document.standard_document_fields.first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "E14WIFE"
      field_value.save!

      #Query for spouse's drivers license
      field_name = "drivers license number"

      #DocytBot Request for wife's info
      service.any_instance.stub(:process_intent) { { :intent => "GetDocumentFieldInfo", :score => score } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me my wife's #{field_name}", :device_type => 'DocytBot' })
      res = service_instance.get_response
     
      expect(res.count).to eq(2)
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/E14WIFE/) ## Match with value of Drivers License

      #DocytBot Request for wifes info
      service.any_instance.stub(:process_intent) { { :intent => "GetDocumentFieldInfo", :score => score } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me my wifes #{field_name}", :device_type => 'DocytBot' })
      res = service_instance.get_response
     
      expect(res.count).to eq(2)
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/E14WIFE/) ## Match with value of Drivers License
    end

    it 'should get drivers license number of spouse when queried for spouse with First Name and not any other drivers license of another contact' do
      #Add Drivers License doc to user.
      sf = StandardFolder.where(:name => 'Personal', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)

      owner = document.uploader
      group = FactoryGirl.create(:group, :owner_id => owner.id)
      #Add coworker for this user
      group_user = FactoryGirl.create(:group_user, :label => GroupUser::COWORKER, :group => group, :user_id => nil)
      document = FactoryGirl.build(:document, :standard_document => sbd, :consumer_id => owner.id, :document_owners => [FactoryGirl.build(:document_owner, :owner => group_user)], :cloud_service_authorization => nil)

      document.save!
      std_field = document.standard_document.standard_document_fields.first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "E14COWORKER"
      field_value.save!

      # Add spouse for this user
      group_user = FactoryGirl.create(:group_user, :label => GroupUser::SPOUSE, :group => group, :user_id => nil, :name => 'Shilpa Dhir')
      document = FactoryGirl.build(:document, :standard_document => sbd, :consumer_id => owner.id, :document_owners => [FactoryGirl.build(:document_owner, :owner => group_user)], :cloud_service_authorization => nil)

      document.save!
      std_field = document.standard_document.standard_document_fields.first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "E14WIFE"
      field_value.save!

      #Query for spouse's drivers license
      field_name = "drivers license number"

      #DocytBot Request for "Shilpa's" info
      service.any_instance.stub(:process_intent) { { :intent => "GetDocumentFieldInfo", :score => score } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me Shilpa's #{field_name}", :device_type => 'DocytBot' })

      res = service_instance.get_response
      expect(res.count).to eq(2)
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/E14WIFE/) ## Match with value of Drivers License

      #DocytBot Request for "Shilpas info"
      service.any_instance.stub(:process_intent) { { :intent => "GetDocumentFieldInfo", :score => score } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me Shilpas #{field_name}", :device_type => 'DocytBot' })
      
      res = service_instance.get_response
      expect(res.count).to eq(2)
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/E14WIFE/) ## Match with value of Drivers License
    end

    it 'should get social security number when queried for one' do
      #Add Social Security doc to user.
      sf = StandardFolder.where(:name => 'Personal', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Social Security Card' }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = document.standard_document.standard_document_fields.first
      std_field.update(encryption: false, speech_text: nil)
      Rails.stub(:user_password_hash) { document.uploader.password_hash('123456') }
      Rails.stub(:app_type) { User::MOBILE_APP }

      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id, :user_id => document.uploader_id)

      owner = document.uploader
      owner.update_oauth_encrypted_private_key_using_pin('123456', 'token1')
      Rails.stub(:user_oauth_token) { 'token1' }
      Rails.stub(:app_type) { User::DOCYT_BOT_APP }

      field_name = "social security number"

      #DocytBot Request
      service.any_instance.stub(:process_intent) { { :intent => "GetDocumentFieldInfo", :score => score, :slots => { :field_name => field_name } } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "show me my #{field_name}", :device_type => 'DocytBot' })

      res = service_instance.get_response
      expect(res.count).to eq(2)
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/#{field_value.value}/)
    end

    it 'should get VIN Number when queried for one' do
      #Add Car Purchase Receipt to user.
      sf = StandardFolder.where(:name => 'Car', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => "Car Purchase Receipt" }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = document.standard_document.standard_document_fields.where("field_id" => 2).first
      Rails.stub(:user_password_hash) { document.uploader.password_hash('123456') }
      Rails.stub(:app_type) { User::MOBILE_APP }

      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id, :user_id => document.uploader_id)

      owner = document.uploader
      owner.update_oauth_encrypted_private_key_using_pin('123456', 'token1')
      Rails.stub(:user_oauth_token) { 'token1' }
      Rails.stub(:app_type) { User::DOCYT_BOT_APP }

      service_instance = service.new(owner, nil, { :field_name => "vin number" })

      field_name = "VIN number"

      #DocytBot Request
      service.any_instance.stub(:process_intent) { { :intent => "GetDocumentFieldInfo", :score => score, :slots => { :field_name => field_name } } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "show me my #{field_name}", :device_type => 'DocytBot' })

      res = service_instance.get_response
      expect(res.count).to eq(2)
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/#{field_value.value}/)
    end

    it 'should get the right Auto Insurance Card when queried with Insurer Name (Descriptor)' do
      #Add Car Purchase Receipt to user.
      sf = StandardFolder.where(:name => 'Car', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => "Auto Insurance Card" }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      owner = document.uploader
      std_field = document.standard_document.standard_document_fields.where("field_id" => 2).first
      Rails.stub(:user_password_hash) { document.uploader.password_hash('123456') }
      Rails.stub(:app_type) { User::MOBILE_APP }

      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id, :user_id => document.uploader_id)
      field_value.input_value = 'AAA Policy Number'
      field_value.save!

      std_field = document.standard_document.standard_document_fields.where("field_id" => 1).first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id, :user_id => document.uploader_id)
      field_value.input_value = "AAA"
      field_value.save!

      document = FactoryGirl.build(:document, :standard_document => sbd, :consumer_id => owner.id, :document_owners => [FactoryGirl.build(:document_owner, :owner => owner)], :cloud_service_authorization => nil)
      document.save!

      std_field = document.standard_document.standard_document_fields.where("field_id" => 2).first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id, :user_id => document.uploader_id)
      field_value.input_value = "Gieco Policy Number"
      field_value.save!

      std_field = document.standard_document.standard_document_fields.where("field_id" => 1).first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id, :user_id => document.uploader_id)
      field_value.input_value = "Gieco"
      field_value.save!

      owner = document.uploader
      owner.update_oauth_encrypted_private_key_using_pin('123456', 'token1')
      Rails.stub(:user_oauth_token) { 'token1' }
      Rails.stub(:app_type) { User::DOCYT_BOT_APP }

      field_name = "policy number"
      descriptor = "Gieco"
      # DocytBot Request
      service.any_instance.stub(:process_intent) { { :intent => "GetDocumentFieldInfo", :score => score, :slots => { :descriptor1 => descriptor } } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me my #{descriptor} #{field_name}", :device_type => 'DocytBot' })
      res = service_instance.get_response
      expect(res.count).to eq(2)
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/Gieco Policy/)
      expect(mes[:message]).to_not match(/AAA Policy/)
    end

    it 'should say I do not know if some unknown field is queried' do
      #Add Drivers License doc to user.
      sf = StandardFolder.where(:name => 'Personal', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Drivers License' }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = document.standard_document.standard_document_fields.first

      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      owner = document.uploader
      field_name = "unknown number"

      #DocytBot Request
      service.any_instance.stub(:process_intent) { { :intent => "GetDocumentFieldInfo", :score => score, :slots => { :field_name => field_name } } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me my #{field_name}", :device_type => 'DocytBot' })

      res = service_instance.get_response
      expect(res.count).to eq(1)

      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/unable to find/)
    end

    it 'should get total amount curency' do
      #Add Drivers License doc to user.
      sf = StandardFolder.where(:name => 'Invoices & Receipts', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Account Receivable' }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = document.standard_document.standard_document_fields.where(:data_type => 'currency').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "200"
      field_value.save!

      std_field2 = document.standard_document.standard_document_fields.where(:name => 'Invoice Date').first
      field_value2 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field2.field_id)
      field_value2.input_value = "09/12/2018"
      field_value2.save!

      owner = document.uploader
      owner.consumer_account_type_id = ConsumerAccountType::BUSINESS
      field_name = "total amount"

      #DocytBot Request
      service.any_instance.stub(:process_intent) { { :intent => "GetCurrencyDocumentsList", :score => score, :slots => { :field_name => field_name } } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me my #{field_name}", :device_type => 'DocytBot' })

      res = service_instance.get_response
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      expect(mes[:message]).to match(/#{field_value.value}/)
    end

    it 'should only get me the total of my meal receipts' do

      #Add Drivers License doc to user.
      sf = StandardFolder.where(:name => 'Invoices & Receipts', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Business Receipts' }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = document.standard_document.standard_document_fields.where(:name => 'Amount').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "300"
      field_value.save!
      
      std_field1 = document.standard_document.standard_document_fields.where(:name => 'Type').first
      field_value1 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field1.field_id)
      field_value1.input_value = "Meal"
      field_value1.save!

      owner = document.uploader

      sf = StandardFolder.where(:name => 'Consumer', :category => true).first
      sbd2 = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Personal Receipt' }).joins(:standard_base_document).first.standard_base_document
      document2 = FactoryGirl.create(:document, :with_owner, uploader: owner, :standard_document => sbd2)
      std_field2 = document2.standard_document.standard_document_fields.where(:name => 'Amount').first
      field_value2 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document2.id, :local_standard_document_field_id => std_field2.field_id)
      field_value2.input_value = "500"
      field_value2.save!

      std_field3 = document2.standard_document.standard_document_fields.where(:name => 'Receipt Type').first
      field_value3 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document2.id, :local_standard_document_field_id => std_field3.field_id)
      field_value3.input_value = "Medical"
      field_value3.save!

      field_name = "meal receipts"
      owner.consumer_account_type_id = ConsumerAccountType::BUSINESS
      #DocytBot Request
      service.any_instance.stub(:process_intent) { { :intent => "GetCurrencyDocumentsList", :score => score, :slots => { :field_name => field_name } } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me the total of my #{field_name}", :device_type => 'DocytBot' })

      res = service_instance.get_response
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      mes2 = res.select { |r| r[:type] == "document_message" }
      expect(mes[:message]).to match(/#{field_value.value}/)
      expect(mes2.map {|x| x[:message][:document].id}).to include(document.id)
      expect(mes2.map {|x| x[:message][:document].id}).not_to include(document2.id)
    end

    it 'should only get the total of my medical expense' do

      #Add Drivers License doc to user.
      sf = StandardFolder.where(:name => 'Invoices & Receipts', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Business Receipts' }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = document.standard_document.standard_document_fields.where(:name => 'Amount').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "300"
      field_value.save!

      std_field1 = document.standard_document.standard_document_fields.where(:name => 'Type').first
      field_value1 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field1.field_id)
      field_value1.input_value = "Meal"
      field_value1.save!

      owner = document.uploader

      sf = StandardFolder.where(:name => 'Consumer', :category => true).first
      sbd2 = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Personal Receipt' }).joins(:standard_base_document).first.standard_base_document
      document2 = FactoryGirl.create(:document, :with_owner, uploader: owner, :standard_document => sbd2)
      std_field2 = document2.standard_document.standard_document_fields.where(:name => 'Amount').first
      field_value2 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document2.id, :local_standard_document_field_id => std_field2.field_id)
      field_value2.input_value = "500"
      field_value2.save!

      std_field3 = document2.standard_document.standard_document_fields.where(:name => 'Receipt Type').first
      field_value3 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document2.id, :local_standard_document_field_id => std_field3.field_id)
      field_value3.input_value = "Medical"
      field_value3.save!

      field_name = "medical expense"
      owner.consumer_account_type_id = ConsumerAccountType::INDIVIDUAL
      #DocytBot Request
      service.any_instance.stub(:process_intent) { { :intent => "GetCurrencyDocumentsList", :score => score, :slots => { :field_name => field_name } } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me the total of my #{field_name}", :device_type => 'DocytBot' })

      res = service_instance.get_response
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      mes2 = res.select { |r| r[:type] == "document_message" }
      expect(mes[:message]).to match(/#{field_value2.value}/)
      expect(mes2.map {|x| x[:message][:document].id}).not_to include(document.id)
      expect(mes2.map {|x| x[:message][:document].id}).to include(document2.id)
    end

    it 'should only get me the total of all my expenses' do

      #Add Drivers License doc to user.
      sf = StandardFolder.where(:name => 'Invoices & Receipts', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Business Receipts' }).joins(:standard_base_document).first.standard_base_document
      document = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = document.standard_document.standard_document_fields.where(:name => 'Amount').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "300"
      field_value.save!

      std_field1 = document.standard_document.standard_document_fields.where(:name => 'Type').first
      field_value1 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document.id, :local_standard_document_field_id => std_field1.field_id)
      field_value1.input_value = "Meal"
      field_value1.save!

      owner = document.uploader

      sf = StandardFolder.where(:name => 'Consumer', :category => true).first
      sbd2 = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Personal Receipt' }).joins(:standard_base_document).first.standard_base_document
      document2 = FactoryGirl.create(:document, :with_owner, uploader: owner, :standard_document => sbd2)
      std_field2 = document2.standard_document.standard_document_fields.where(:name => 'Amount').first
      field_value2 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document2.id, :local_standard_document_field_id => std_field2.field_id)
      field_value2.input_value = "500"
      field_value2.save!

      std_field3 = document2.standard_document.standard_document_fields.where(:name => 'Receipt Type').first
      field_value3 = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => document2.id, :local_standard_document_field_id => std_field3.field_id)
      field_value3.input_value = "Medical"
      field_value3.save!

      field_name = "expenses"
      owner.consumer_account_type_id = ConsumerAccountType::BUSINESS
      #DocytBot Request
      service.any_instance.stub(:process_intent) { { :intent => "GetCurrencyDocumentsList", :score => score, :slots => { :field_name => field_name } } }
      service_instance = service.new(owner, docyt_bot_session, { :text => "get me the total of all my #{field_name}", :device_type => 'DocytBot' })

      res = service_instance.get_response
      expect(res.find { |r| r[:type] == "regular_message" }).to_not be_nil
      expect(res.find { |r| r[:type] == "document_message" }).to_not be_nil
      mes = res.find { |r| r[:type] == "regular_message" }
      mes2 = res.select { |r| r[:type] == "document_message" }
      expect(mes[:message]).to match(/800/)
      expect(mes2.map {|x| x[:message][:document].id}).to include(document.id, document2.id)
    end

  end

end
