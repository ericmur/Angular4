class Api::DocytBot::V1::Filters::ReceiptTypeFilter < Api::DocytBot::V1::Filters::BaseFilter
  def initialize(user, ctx)
    @user = user
    @ctx = ctx
    @intent = ctx[:intent]
    @pre_filter_docs_ids = ctx[:document_ids]
  end

  def call
    Rails.logger.debug "[DocytBot] Processing filter: ReceiptTypeFilter"
    document_ids = []
    business_receipt_request_found = nil
    if is_business_account?
      receipt_type = nil
      business_receipt_request_found = BaseDocumentField::BUSINESS_RECEIPT_TYPES_VALUES.find { |receipt_value|
        receipt_type = receipt_value
        @ctx[:text].match((receipt_value + " expense").downcase) or @ctx[:text].match((receipt_value + " receipt").downcase) or @ctx[:text].match((receipt_value + " expenditure").downcase)
      }
      receipt_type = nil if business_receipt_request_found.nil?

      business_document_ids = BusinessDocument.where(:business_id => @user.businesses.pluck(:id)).pluck(:document_id)
      shared_business_document_ids = SymmetricKey.where(:document_id => business_document_ids).for_user_access(@user.id).pluck(:document_id)
      docs_ids = @pre_filter_docs_ids + shared_business_document_ids
      
      if business_receipt_request_found or @ctx[:text].match("receipt")
        Rails.logger.debug "[DocytBot] Business ReceiptType: #{receipt_type}"
        std_doc = StandardDocument.find(StandardDocument::BUSINESS_RECEIPT_ID)
        receipt_type_field = std_doc.standard_document_fields.where(:name => 'Type').first
        raise "Type field not found in Business Receipt document" if receipt_type_field.nil?
        docs_ids = Document.where(:id => docs_ids, :standard_document_id => std_doc.id)
        cond = DocumentFieldValue.where(:document_id => docs_ids, :local_standard_document_field_id => receipt_type_field.field_id)
        if receipt_type
          cond = cond.where("value ilike '%#{receipt_type}'") #ilike is used because we have Gas/Mileage type which can be queried as Gas or Mileage and also for case insensitive search
        end
        
        document_ids += cond.pluck(:document_id)
        Rails.logger.debug "[DocytBot] Business Receipt Documents matched: #{document_ids.inspect}"
      else
        #Look at all documents inside "Business Invoices/Receipts" folder.
        Rails.logger.debug "[DocytBot] Scanning entire Business Invoices/Receipt folder"
        std_doc_ids = StandardFolder.find(StandardFolder::BUSINESS_INVOICES_ID).standard_folder_standard_documents.pluck(:standard_base_document_id)
        document_ids += Document.where(:id => docs_ids, :standard_document_id => std_doc_ids).pluck(:id)
      end
    end

    #Now go through Personal receipts
    personal_receipt_request_found = BaseDocumentField::PERSONAL_RECEIPT_TYPES_VALUES.find { |receipt_value|
      receipt_type = receipt_value
      @ctx[:text].match((receipt_value + " expense").downcase) or @ctx[:text].match((receipt_value + " receipt").downcase) or @ctx[:text].match((receipt_value + " expenditure").downcase)
    }

    std_doc = StandardDocument.find(StandardDocument::PERSONAL_RECEIPT_ID)
    receipt_type_field = std_doc.standard_document_fields.where(:name => 'Receipt Type').first
    raise "Type field not found in Personal Receipt document" if receipt_type_field.nil?
    docs_ids = Document.where(:id => @pre_filter_docs_ids, :standard_document_id => std_doc.id).pluck(:id)
    cond = DocumentFieldValue.where(:document_id => docs_ids, :local_standard_document_field_id => receipt_type_field.field_id)
    if personal_receipt_request_found
      Rails.logger.debug "[DocytBot] Personal ReceiptType: #{receipt_type}"
      document_ids = [] #Reset business document_ids since user requested a specific personal receipt type.
      
      cond = cond.where("value ilike '%#{receipt_type}'")
      document_ids += cond.pluck(:document_id)
      Rails.logger.debug "[DocytBot] Personal Receipt Documents matched: #{document_ids.inspect}"
    else
      #if no specific personal receipt was found then only search through all personal receipts if no specific business receipt type was requested
      if business_receipt_request_found.nil?
        Rails.logger.debug "[DocytBot] Scanning entire personal receipts"
        document_ids += cond.pluck(:document_id)
      end
    end

    Rails.logger.debug "[DocytBot] Filtered documents after applying ReceiptTypeFilter: #{document_ids}"
    @ctx[:document_ids] = document_ids
    return @ctx
  end

  private

  def is_business_account?
    if @user.consumer_account_type_id == ConsumerAccountType::BUSINESS
      return true
    else
      return false
    end
  end
end
