class Api::Mobile::V2::StandardDocumentsController < Api::Mobile::V2::ApiController
  include UserAccessibilityForController
  before_action :load_standard_base_document, only: [:update, :update_fields]
  before_action only: [:create, :update] { |c| c.send(:verify_permission_create, params) } #use send since it is a private method
  before_action :verify_permission_for_edit, only: [:update, :update_fields]
  before_action :verify_permission_for_create, only: [:create]

  def index
    @standard_documents_json = DocumentCacheService.new(current_user, params).get_standard_base_documents_json
    render status: 200, json: @standard_documents_json
  end

  def create
    standard_folder_id = params[:standard_base_document][:standard_folder_id]
    standard_document_fields = params[:standard_base_document][:standard_document_fields]
    params[:standard_base_document].reject!{|k, _| k.to_s == "standard_folder_id" }
    params[:standard_base_document].reject!{|k, _| k.to_s == "standard_document_fields" }
    @standard_document = StandardDocumentBuilder.new(current_user, standard_base_document_params, params[:owners], standard_document_fields, standard_folder_id).create_standard_document

    if @standard_document.persisted?
      DocumentCacheService.update_cache([:standard_document], @standard_document.consumer_ids_for_owners)

      render status: 200, json: @standard_document, serializer: ::Api::Mobile::V2::StandardBaseDocumentSerializer, root: 'standard_base_document'
    else
      render status: 422, json: { errors: @standard_document.errors.full_messages }
    end
  end

  def update
    if params[:owners].present?
      params[:owners].each do |owner_hash|
        if owner_hash["owner_type"] == "GroupUser"
          group_user = GroupUser.find(owner_hash['owner_id'])
          @standard_base_document.owners.create!(owner: group_user) if @standard_base_document.owners.where(owner: group_user).count == 0
        elsif owner_hash["owner_type"] == "Consumer" or owner_hash["owner_type"] == "User"
          user = User.find(owner_hash['owner_id'])
          @standard_base_document.owners.create!(owner: user) if @standard_base_document.owners.where(owner: user).count == 0
        end
      end
    else
      user = User.find(self.current_user.id)
      @standard_base_document.owners.create!(owner: user) if @standard_base_document.owners.where(owner: user).count == 0
    end

    DocumentCacheService.update_cache([:standard_document], @standard_base_document.consumer_ids_for_owners)

    render status: 200, json: { owners: @standard_base_document.owners.map{|o| { owner_type: o.owner_type, owner_id: o.owner_id } } }
  end

  def update_fields
    fields_params = params[:standard_base_document][:standard_document_fields]
    errors = []
    ActiveRecord::Base.transaction do
      begin
        field_id = @standard_base_document.standard_document_fields.maximum(:field_id)
        fields_params.each do |field_param|
          if field_param["delete"].present?
            @standard_base_document.standard_document_fields.where(id: field_param["id"]).destroy_all
          elsif field_param["id"].present?
            field = @standard_base_document.standard_document_fields.where(id: field_param["id"]).first
            field.name = field_param["name"]
            field.save!
          else
            field_id += 1
            StandardDocumentBuilder.new(current_user, {}, [], [field_param], nil).create_fields!(@standard_base_document, field_id)
          end
        end
        @standard_base_document.save!

      rescue => e
        errors = [e.message]
      end
    end
    if errors.empty?
      DocumentCacheService.update_cache([:standard_document], @standard_base_document.consumer_ids_for_owners)
      render status: 200, json: @standard_base_document, serializer: ::Api::Mobile::V2::StandardBaseDocumentSerializer, root: 'standard_base_document'
    else
      render status: 422, json: { errors: errors }
    end
  end

  private

    def standard_base_document_params
      params.require(:standard_base_document).permit(:name, :standard_folder_id)
    end
    
    def load_standard_base_document
      @standard_base_document = StandardDocument.where(id: params[:id]).first
    end

    def verify_permission_for_edit
      unless @standard_base_document.consumer_ids_for_owners.include?(current_user.id)
        render status: 422, json: { errors: ["You don't have permissions to modify this document type"] }
      end
    end

    def verify_permission_for_create
      standard_folder = StandardFolder.find(standard_base_document_params[:standard_folder_id])
      unless standard_folder.is_writeable_by_user?(current_user)
        render status: 422, json: { errors: ['You don\'t have the permissions to create this type of document'] }
      end
    end

end
