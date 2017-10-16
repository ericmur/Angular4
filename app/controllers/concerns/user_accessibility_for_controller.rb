require 'active_support/concern'

module UserAccessibilityForController
  extend ActiveSupport::Concern

  private
  def verify_permission_create(params)
    #Create a standard_base_document/document for another group user only if you have permissions to create a standard_base_document/document for him
    if controller_name == 'documents'
      owners_params = params[:document_owners]
    elsif controller_name == 'standard_base_documents' || controller_name == 'standard_documents'
      owners_params = params[:owners]
    elsif controller_name == 'standard_folders'
      owners_params = params[:owners]
    else
      raise "Invalid controller: #{controller_name}"
    end
    
    if owners_params
      non_connected_guids = owners_params.select { |owner_params| owner_params['owner_type'] == 'GroupUser' }.map { |owner_params| owner_params[:owner_id] }
      non_connected_guids.each do |guid|
        if gu = GroupUser.where(:id => guid, :group_id => self.current_user.groups_as_owner.select(:id).map(&:id)).first
          return true
          #For now you can upload a document for any group user (atleast while we are only doing Family Group)
=begin
          if gu.user_id
            check_for_access_perms(gu.user_id)
          end
=end
        else
          respond_invalid_perms
        end
      end
      #For now you can upload a document for any group user (atleast while we are only doing Family Group)
=begin
      connected_uids = owners_params.select { |owner_params| ["Consumer", "User"].include?(owner_params[:owner_type]) }.map { |owner_params| owner_params[:owner_id] }
      connected_uids.each do |uid|
        check_for_access_perms(uid)
      end
=end
    end
  end

  def check_for_access_perms(uid)
    ua = self.current_user.user_accesses.where(:user_id => uid).first
    if ua.nil?
      respond_invalid_perms
    end
  end

  def respond_invalid_perms
    respond_to do |format|
      format.json { render :json => { :errors => ["You don't have permissions to create a document type for this user"] }, :status => :not_acceptable } and return
    end
  end
end
