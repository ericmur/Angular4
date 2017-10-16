require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::DocytBot::V1::Filters::DescriptorFilter do
  before do
    load_standard_documents
    load_docyt_support
    @user = FactoryGirl.create(:consumer)
    load_startup_keys
  end

  let!(:filter)  { Api::DocytBot::V1::Filters::DescriptorFilter }

  context "query: get me my konica invoices" do
    before do
      sf = StandardFolder.where(:name => 'Invoices & Receipts', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Account Payable' }).joins(:standard_base_document).first.standard_base_document

      #Add Konica Minolta invoice
      @document1 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = @document1.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document1.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Konica Minolta"
      field_value.save!

      #Add kelly paper invoice
      @document2 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = @document2.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document2.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Kelly Paper Inc"
      field_value.save!


      @ctx = { :text => 'get me my konica minolta invoices', :document_ids => [@document1.id, @document2.id] }
    end

    it 'should get only konica minolta invoices' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).to include(@document1.id)
    end

    it 'should not get kelly paper invoices' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).not_to include(@document2.id)
    end
  end

  context "query: get me my ebay Inc. invoices in conflict with Moving Bay Area Supplies" do
    before do
      sf = StandardFolder.where(:name => 'Invoices & Receipts', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Account Payable' }).joins(:standard_base_document).first.standard_base_document

      #Add Ebay Incorporated invoice
      @document1 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = @document1.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document1.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Ebay Inc"
      field_value.save!

      #Add Moving Bay Area Supplies invoice
      @document2 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = @document2.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document2.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Moving Bay Area Supplies"
      field_value.save!


      @ctx = { :text => 'get me my ebay Inc invoices', :document_ids => [@document1.id, @document2.id] }
    end

    it 'should get only ebay Inc. invoices' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).to include(@document1.id)
    end

    it 'should not get Moving Bay Area Supplies invoices' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).not_to include(@document2.id)
    end
  end

  context "query: get me my ebay Inc. invoices in conflict with Amazon Inc." do
    before do
      sf = StandardFolder.where(:name => 'Invoices & Receipts', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Account Payable' }).joins(:standard_base_document).first.standard_base_document

      #Add Ebay Incorporated invoice
      @document1 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = @document1.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document1.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Ebay Inc."
      field_value.save!

      #Add Moving Bay Area Supplies invoice
      @document2 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = @document2.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document2.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Amazon Inc."
      field_value.save!


      @ctx = { :text => 'get me my ebay Inc invoices', :document_ids => [@document1.id, @document2.id] }
    end

    it 'should get only ebay Inc. invoices' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).to include(@document1.id)
    end

    it 'should not get Amazon Inc. invoices' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).not_to include(@document2.id)
    end
  end

  context "query: get me the total of my Konica Minolta invoices between January 2016 and March 2016. Ensure only Konica Minolta invoices are filtered here" do
    before do
      sf = StandardFolder.where(:name => 'Invoices & Receipts', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Account Payable' }).joins(:standard_base_document).first.standard_base_document

      #Add Konica Minolta invoice
      @document1 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = @document1.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document1.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Konica Minolta"
      field_value.save!

      std_field = @document1.standard_document.standard_document_fields.where(:name => 'Business Name').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document1.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "UPS Store 2762"
      field_value.save!

      std_field = @document1.standard_document.standard_document_fields.where(:name => 'Item/Service').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document1.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Maintenance Service"
      field_value.save!

      #Add County of Santa Clara invoice
      @document2 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sbd)
      std_field = @document2.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document2.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "County of Santa Clara"
      field_value.save!

      std_field = @document2.standard_document.standard_document_fields.where(:name => 'Item/Service').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document2.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Registration fee for Weights and Measures Devices"
      field_value.save!

      @ctx = { :text => 'get me the total of my Konica Minolta invoices between January 2016 and March 2016', :document_ids => [@document1.id, @document2.id] }
    end
    
    it 'should only get Konica Minolta invoices' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).to include(@document1.id)
    end

    it 'should not get County of Santa Clara invoice' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).not_to include(@document2.id)
    end
  end
end
