class StandardDocumentBuilder
  include Mixins::StandardBaseDocumentHelper

  def initialize(current_user, standard_document_params, owners_params, fields_params, standard_folder_id)
    @standard_document_params = standard_document_params
    @standard_folder_id = standard_folder_id
    @fields_params = fields_params.present? ? fields_params : []
    @owners_params = owners_params
    @current_user = current_user
  end

  def standard_folder
    @standard_folder ||= StandardFolder.find(@standard_folder_id)
  end

  def with_pages?
    [nil, true].include?(standard_folder.with_pages)
  end

  def create_standard_document
    @standard_document = @current_user.standard_base_documents_by_me.build(@standard_document_params.merge(:type => 'StandardDocument')) do |standard_document|
      standard_document.created_by = @current_user
      standard_document.default = true
      standard_document.with_pages = with_pages?
      set_owners(standard_document)
      set_permissions(standard_document)
      create_standard_folder_standard_document(standard_document)
    end
    ActiveRecord::Base.transaction(requires_new: true) do
      begin
        @standard_document.save!
        @standard_document.owners.each do |std_doc_owner|
          unless standard_folder.owners.where(owner: std_doc_owner.owner).exists?
            standard_folder.owners.create!(owner: std_doc_owner.owner)
          end
        end if standard_folder.consumer_id.present?
        set_standard_base_document_account_type(@standard_document)
        create_fields!(@standard_document)
      rescue => e
        @standard_document.errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end
    end
    return @standard_document
  end

  def create_fields!(standard_document, start_field_id=1)
    field_id = start_field_id
    @fields_params.each do |fields_param|
      field_type = nil
      field_name = fields_param['name']
      data_type = fields_param['data_type']
      notify = BaseDocumentField::ALERT_DATA_TYPES.include?(data_type)
      encryption = fields_param['encryption']
      field_id += 1

      field = BaseDocumentField.new(
        standard_document_id: standard_document.id,
        name: field_name,
        data_type: data_type,
        type: "StandardDocumentField",
        field_id: field_id,
        notify: notify,
        encryption: encryption,
        created_by_user_id: @current_user.id)

      if data_type == 'due_date'
        NotifyDuration::DEFAULT_DUE_NOTIFY_DURATIONS.each do |n|
          field.notify_durations.build(amount: n[:amount], unit: n[:unit])
        end
      elsif data_type == 'expiry_date'
        NotifyDuration::DEFAULT_EXPIRY_NOTIFY_DURATIONS.each do |n|
          field.notify_durations.build(amount: n[:amount], unit: n[:unit])
        end
      end

      field.save!
    end
  end

  private

    def set_standard_base_document_account_type(standard_base_document)
      standard_folder.standard_base_document_account_types.each do |standard_base_document_account_type|
        standard_base_document.standard_base_document_account_types.create!(consumer_account_type_id: standard_base_document_account_type.consumer_account_type_id)
      end
    end

    def create_standard_folder_standard_document(standard_document)
      standard_document.standard_folder_standard_documents.build(standard_folder_id: @standard_folder_id)
    end
end
