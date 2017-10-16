require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe Api::DocytBot::V1::Filters::CurrencyComputeFilter do
  before do
    load_standard_documents
    load_docyt_support
    @user = FactoryGirl.create(:consumer)
    load_startup_keys
  end

  let!(:filter)  { Api::DocytBot::V1::Filters::CurrencyComputeFilter }

  context "query: get total amount of currency" do
    before do

      sd1 = StandardDocument.where(:name => 'Account Receivable').first
      sd2 = StandardDocument.where(:name => 'Account Payable').first

      @document1 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sd1)
      std_field = @document1.standard_document.standard_document_fields.where(:data_type => 'currency').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document1.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "120"
      field_value.save!

      @document2 = FactoryGirl.create(:document, :with_uploader_and_owner, :standard_document => sd2)
      std_field = @document2.standard_document.standard_document_fields.where(:data_type => 'currency').first
      field_value = FactoryGirl.create(:document_field_value, :with_text_value, :document_id => @document2.id, :local_standard_document_field_id => std_field.field_id)
      field_value.input_value = "200"
      field_value.save!

      @ctx = { :text => 'get my total amount', :document_ids => [@document1.id, @document2.id] }
    end

    it 'should get total amount of currency' do
      ctx = filter.new(@user, @ctx).call
      expect(ctx[:total]).to eq("320".to_i)
    end

  end
end
