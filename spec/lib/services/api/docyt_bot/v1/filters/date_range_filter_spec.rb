require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::DocytBot::V1::Filters::DateRangeFilter do
  before do
    load_standard_documents
    load_docyt_support
    @user = FactoryGirl.create(:consumer)
    load_startup_keys
  end

  def create_doc(sbd)
    FactoryGirl.create(:document, :with_owner, :standard_document => sbd, :uploader => @user, :cloud_service_authorization => nil)
  end

  let!(:filter)  { Api::DocytBot::V1::Filters::DateRangeFilter }

  context "query: get me my konica invoices from January" do
    before do
      sf = StandardFolder.where(:name => 'Invoices & Receipts', :category => true).first
      sbd = sf.standard_folder_standard_documents.where(:standard_base_documents => { :name => 'Account Payable' }).joins(:standard_base_document).first.standard_base_document

      #Add Konica Minolta invoice from Jan
      @document1 = create_doc(sbd)
      #document = FactoryGirl.create(:document, :with_owner, :standard_document => sbd, :uploader => @user)
      #document = FactoryGirl.create(:document, :with_owner, :standard_document => sbd, :uploader => @user)
      std_field = @document1.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document1.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Konica Minolta"
      field_value.save!

      date_std_field = @document1.standard_document.standard_document_fields.where(:name => 'Invoice Date').first
      date_field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document1.id, :local_standard_document_field_id => date_std_field.field_id)
      date_field_value.input_value = "01/09/2017"
      date_field_value.save!

      #Add Konica invoice from Feb
      @document2 = create_doc(sbd)
      std_field = @document2.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document2.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Konica Minolta"
      field_value.save!

      date_std_field = @document2.standard_document.standard_document_fields.where(:name => 'Invoice Date').first
      date_field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document2.id, :local_standard_document_field_id => date_std_field.field_id)
      date_field_value.input_value = "02/09/2017"
      date_field_value.save!

      #Add kelly paper invoice

      @document3 = create_doc(sbd)
      std_field = @document3.standard_document.standard_document_fields.where(:name => 'Merchant').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document3.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "Kelly Paper"
      field_value.save!

      date_std_field = @document3.standard_document.standard_document_fields.where(:name => 'Invoice Date').first
      date_field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document3.id, :local_standard_document_field_id => date_std_field.field_id)
      date_field_value.input_value = "02/21/2017"
      date_field_value.save!
      @ctx = { :text => 'get me my konica invoices from january', :document_ids => [@document1.id, @document2.id, @document3.id] }
    end

    it 'should get only konica minolta invoices from January' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).to include(@document1.id)
    end

    it 'should not get konica invoices that are not from January' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:document_ids]).not_to include(@document2.id)
    end
  end
end
