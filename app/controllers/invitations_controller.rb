class InvitationsController < ApplicationController
  layout 'simple'
  skip_before_action :doorkeeper_authorize!, only: [:preview, :referral]
  skip_before_action :confirm_phone!, only: [:preview, :referral]
  skip_before_action :confirm_device_uuid!, only: [:preview, :referral]
  before_action :verify_has_no_invitation, only: [:create]
  before_action :load_invitation, only: [:accept, :reject, :reinvite, :cancel]
  before_action :verify_selected_group_user_or_label, only: [:accept]
  before_action :verify_invitation_source, only: [:preview, :accept]
  after_action :set_invitation_notification_as_read, only: [:accept, :reject]

  def create
    @invitation = Invitationable::ConsumerToConsumerInvitation.new(invitation_params)
    @invitation.created_by_user = current_user
    if @invitation.save
      respond_to do |format|
        format.json { render :json => @invitation, serializer: InvitationSerializer, root: 'invitation', :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => @invitation.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def preview
    @invitation = Invitationable::Invitation.find_by_token(params[:token])
    @invitation_source = params[:source] ? params[:source] : Invitationable::Invitation::SOURCE[:email]
    respond_to do |format|
      if @invitation && @invitation.pending?
        if @invitation_source == Invitationable::Invitation::SOURCE[:email]
          format.html { redirect_to app_launcher_path(path: "/email_invitation/#{@invitation.id}" ) }
        else
          format.html { redirect_to app_launcher_path(path: "/text_invitation/#{@invitation.id}" ) }
        end
      else
        flash[:notice] = I18n.t('errors.invitation.invalid_source')
        format.html
      end
    end
  end

  def referral
    respond_to do |format|
      format.html
    end
  end

  def show
    @invitation = Invitationable::Invitation.find_by_id(params[:id])
    respond_to do |format|
      if @invitation
        format.json { render :json => @invitation, serializer: InvitationDetailedSerializer, root: 'invitation', :status => :ok }
      else
        format.json { render :json => { }, :status => :ok }
      end
    end
  end

  def accept
    invitation =  if @invitation.invitation_type == Invitationable::ConsumerToConsumerInvitation::INVITATION_TYPE
                    @invitation.accept_invitation!(current_user, params[:group_user_id], params[:group_user_label], params[:source])
                  elsif @invitation.invitation_type == Invitationable::AdvisorToConsumerInvitation::INVITATION_TYPE
                    @invitation.accept_invitation!(current_user, params[:source])
                  end

    if invitation
      respond_to do |format|
        if @invitation.invitation_type == Invitationable::AdvisorToConsumerInvitation::INVITATION_TYPE
          format.json { render :json => @invitation, serializer: InvitationAdvisorAcceptedSerializer, root: 'invitation', :status => :ok }
        else
          format.json { render :json => @invitation, serializer: InvitationAcceptedSerializer, root: 'invitation', :status => :ok }
        end
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => @invitation.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def reject
    @invitation.rejected_by_user = current_user
    if @invitation.reject!
      respond_to do |format|
        format.json { render :json => @invitation, serializer: InvitationSerializer, root: 'invitation', :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => @invitation.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def cancel
    if @invitation.destroy
      respond_to do |format|
        format.json { render :json => [] }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => @invitation.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def reinvite
    @group_user = @invitation.group_user if @invitation.invitation_type == Invitationable::ConsumerToConsumerInvitation::INVITATION_TYPE
    if @invitation.invitation_type == Invitationable::AdvisorToConsumerInvitation::INVITATION_TYPE
      @advisor = @invitation.created_by_user
      @client = @invitation.client
    end

    @invitation.destroy

    @new_invitation = recreate_invitation_by_type(@invitation, invitation_params)

    if @new_invitation.save
      respond_to do |format|
        format.json { render :json => @new_invitation, serializer: InvitationSerializer, root: 'invitation', :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => @invitation.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def first_time_invitations
    invitations = current_user.notifications.where(notification_type: Notification.notification_types[:invitation_created]).map(&:notifiable).reject(&:nil?)
    respond_to do |format|
      format.json { render :json => invitations, each_serializer: InvitationDetailedSerializer, root: 'invitations', :status => :ok }
    end
  end

  private

  def recreate_invitation_by_type(old_invitation, invitation_params)
    if old_invitation.invitation_type == Invitationable::ConsumerToConsumerInvitation::INVITATION_TYPE
      new_invitation = Invitationable::ConsumerToConsumerInvitation.new(invitation_params)
      new_invitation.created_by_user = current_user
      new_invitation.group_user = @group_user
    elsif old_invitation.invitation_type == Invitationable::AdvisorToConsumerInvitation::INVITATION_TYPE
      new_invitation = Invitationable::AdvisorToConsumerInvitation.new(invitation_params)
      new_invitation.created_by_user = @advisor
      new_invitation.client = @client
    else
      new_invitation = Invitationable::Invitation.new
    end

    new_invitation
  end

  def verify_selected_group_user_or_label
    return true if @invitation.invitation_type == Invitationable::AdvisorToConsumerInvitation::INVITATION_TYPE
    if params[:group_user_id].blank? && params[:group_user_label].blank?
      respond_to do |format|
        format.json { render :json => { :errors => [I18n.t("errors.invitation.require_label_selection")] }, :status => :not_acceptable }
      end
    end
  end

  def invitation_params
    params.require(:invitation).permit(:email, :phone, :email_invitation, :text_invitation, :group_user_id, :invitee_type)
  end

  def load_invitation
    @invitation = Invitationable::Invitation.find(params[:id])
  end

  def verify_invitation_source
    unless params[:source] == nil || Invitationable::Invitation::SOURCE.map{ |_,v| v }.include?(params[:source])
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t('errors.invitation.invalid_source')
          render :action => 'preview'
        end
        format.json { render :json => { :errors => [I18n.t('errors.invitation.invalid_source')] }, :status => :not_acceptable }
      end
    end
  end

  def verify_has_no_invitation
    if params[:invitation][:group_user_id].present?
      @group_user = GroupUser.find(params[:invitation][:group_user_id])
      if @group_user.invitation.present?
        respond_to do |format|
          format.json { render :json => { :errors => [I18n.t('errors.invitation.already_invited')] }, :status => :not_acceptable }
        end
      end
    end
  end

  def set_invitation_notification_as_read
    if response.code == '200'
      notifications = current_user.notifications.where(notifiable: @invitation, notification_type: Notification.notification_types[:invitation_created])
      notifications.update_all(unread: false)
    end
  end

end
