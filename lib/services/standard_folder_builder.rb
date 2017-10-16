class StandardFolderBuilder
  include Mixins::StandardBaseDocumentHelper

  def initialize(current_user, standard_folder_params, owners_params, params)
    @standard_folder_params = standard_folder_params
    @owners_params = owners_params
    @current_user = current_user
    @params = params
  end

  def create_folder
    @standard_folder = StandardFolder.new(@standard_folder_params) do |folder|
      folder.created_by = @current_user
      folder.category = true
      folder.icon_name_2x = "Misc_icon@2x.png"
      folder.icon_name_3x = "Misc_icon@3x.png"
      set_owners(folder)
      set_permissions(folder)
    end

    ActiveRecord::Base.transaction(requires_new: true) do
      begin
        @standard_folder.save!
        set_standard_base_document_account_type(@standard_folder)
      rescue => e
        @standard_folder.errors.add(:base, e.message)
        raise ActiveRecord::Rollback
      end
    end

    @standard_folder
  end

  private

    def set_standard_base_document_account_type(standard_base_document)
      account_type = ConsumerAccountType.find_by_id(@params['standard_base_document_account_type_id'])
      account_type = ConsumerAccountType.individual_type.first if account_type.nil?
      if account_type.business?
        businesses = standard_base_document.owners.where(owner_type: 'Business')
        if businesses.count == 0
          raise "You are not permitted to create Business document."
        end
        businesses.map { |b| b.owner }.each do |business|
          unless business.business_partner?(@current_user)
            raise "You are not permitted to create Business document."
          end
        end
      end
      standard_base_document.standard_base_document_account_types.create!(consumer_account_type_id: account_type.id)
    end
end