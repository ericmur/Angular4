class GroupUsersController < ApplicationController
  before_action :load_group, :except => [:set_user]
  before_action :load_group_user, :only => [:set_user, :destroy, :update, :unlink]
  before_action :load_user_password_hash, :only => [:set_user]
  before_action :verify_unassigned_group_user, :only => [:set_user]
  before_action :verify_no_documents_conflict, :only => [:set_user]
  before_action :verify_disconnected_group_user, only: [:destroy]
  before_action :verify_connected_group_user, only: [:unlink]
  before_action :check_document_accesss_request_by_current_user, only: [:unlink, :destroy]
  before_action :check_document_access_request_for_current_user, only: [:unlink, :destroy]

  def index
    group_users = @group.group_users
    respond_to do |format|
      format.json { render :json => group_users }
    end
  end

  # Skip lookup to group_user's group since we are going to fetch group_user that doesn't belongs to current_user group
  # However this should only happens for this action only. Otherwise please lookup to group first before loading group_user
  def show
    @group_user = GroupUser.find(params[:id])
    respond_to do |format|  
      format.json { render :json => @group_user }
    end
  end

  def create
    @group_user = @group.group_users.build(group_user_params)

    if @group_user.require_business? && @group_user.business.blank?
      businesses = Business.for_user(current_user)
      # we will only set business automatically if there's only one business for current_user
      if businesses.count == 1
        @group_user.business = businesses.first
      end
    end

    respond_to do |format|
      if @group_user.save
        #First time setup of this group_user, lets setup folders
        Permission.setup_system_documents_permissions_for_contact(current_user, @group_user)
        @group_user.generate_folder_settings(current_user, @group_user.label)
        format.json { render :json => @group_user }
      else
        # TODO: try to find better way to do this. As for now if phone number error detected, we will only reponse with phone's error message
        if @group_user.errors[:phone].present?
          errors = @group_user.errors.full_messages_for(:phone)
        else
          errors = @group_user.errors.full_messages
        end

        format.json { render :json => { :errors => errors }, :status => :not_acceptable }
      end
    end
  end

  def update
    respond_to do |format|
      if @group_user.update(group_user_params)
        format.json { render :json => @group_user }
      else
        format.json { render :json => { :errors => @group_user.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def set_user
    if @group_user.set_user(params[:group_user][:user_id])
      respond_to do |format|
        format.json { render :json => @group_user }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => @group_user.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def destroy
    @group_user.destroy
    respond_to do |format|
      format.json { render :json => @group_user }
    end
  end

  def unlink
    @group_user.unlink! do |success, message|
      respond_to do |format|
        if success
          format.json { render :json => @group_user }
        else
          format.json { render :json => { :errors => [message] }, :status => :not_acceptable }
        end
      end  
    end
  end

  def share_with_advisor
    @advisor = User.with_standard_category.find(params[:advisor_id])
    @group_user = current_user.group_users_as_group_owner.find(params[:id])
    @advisor_group_user = @group_user.share_with_advisor(@advisor)

    if @advisor_group_user.persisted?
      respond_to do |format|
        format.json { render status: 200, json: @group_user }
      end
    else
      respond_to do |format|
        format.json { render status: 422, json: { errors: @advisor_group_user.errors.full_messages } }
      end
    end
  end

  def revoke_share_with_advisor
    @advisor = User.with_standard_category.find(params[:advisor_id])
    @group_user = current_user.group_users_as_group_owner.find(params[:id])
    @group_user.unshare_with_advisor(@advisor)

    respond_to do |format|
      format.json { render status: 200, json: @group_user }
    end
  end

  private
  def group_user_params
    #If user_id is provided then we don't save name, dob, email, phone in group_user since this data is saved in user model anyway
    if action_name == 'set_user'
      params.require(:group_user).permit(:user_id)
    else
      params.require(:group_user).permit(:name, :email, :phone, :label, :profile_background, :email_invitation, :text_invitation)
    end
  end

  def load_group
    @group = self.current_user.groups_as_owner.where(:id => params[:group_id]).first
  end

  def load_group_user
    if @group
      @group_user = @group.group_users.where(:id => params[:id]).first
    else
      group_ids = Group.where(:owner_id => self.current_user.id).select(:id)
      @group_user = GroupUser.where(:id => params[:id]).where(:group_id => group_ids).first
    end
  end

  def verify_disconnected_group_user
    if @group_user.connected?
      respond_to do |format|
        format.json { render :json => { :errors => [I18n.t('errors.group_user.cannot_delete_connected')] }, :status => :not_acceptable }
      end
    end
  end

  def verify_connected_group_user
    unless @group_user.connected?
      respond_to do |format|
        format.json { render :json => @group_user, :status => :ok }
      end
    end
  end

  def verify_unassigned_group_user
    if @group_user.user_id
      respond_to do |format|
        format.json { render :json => { :errors => [I18n.t('errors.group_user.already_assigned')] }, :status => :not_acceptable }
      end
    end
  end

  #We will need to change this before_filter in the future. If both group_user and user being transferred to have documents, then these documents have to just be merged together
  def verify_no_documents_conflict
    if @group_user.document_ownerships.first and DocumentOwner.where(:owner_id => params[:group_user][:user_id], :owner_type => ['User', 'Consumer']).first
      respond_to do |format|
        format.json { render :json => { :errors => [I18n.t('errors.group_user.document_conflict')] }, :status => :not_acceptable }
      end
    end
  end

  def check_document_accesss_request_by_current_user
    @access_requests_by_current_user = DocumentAccessRequest.uploaded_by(@group_user.user_id).created_by(current_user.id)
    count = @access_requests_by_current_user.count
    if count > 0
      desc = @access_requests_by_current_user.limit(2).map{ |r| r.description }
      desc.append('...') if count > 2

      message = <<-MSG
      There are #{count} documents (#{desc.join(', ')}) for which #{@group_user.user.first_name} is the owner. 
      However #{@group_user.user.first_name} does not have access. 
      Grant him access or remove him as owner from these documents before unlinking
      MSG

      respond_to do |format|
        format.json { render status: 422, json: { errors: [message] } }
      end
    end
  end

  def check_document_access_request_for_current_user
    @access_request_for_current_user = DocumentAccessRequest.uploaded_by(current_user.id).created_by(@group_user.user_id)
    count = @access_request_for_current_user.count
    if count > 0
      desc = @access_request_for_current_user.limit(2).map{ |r| r.description }
      desc.append('...') if count > 2
      message = <<-MSG
      There are #{count} documents (#{desc.join(', ')}) for which you are the owner.
      However you do not have access.
      Request access for these documents or ask the other side to remove you as owner from these documents before unlinking
      MSG

      respond_to do |format|
        format.json { render status: 422, json: { errors: [message] } }
      end
    end
  end
end
