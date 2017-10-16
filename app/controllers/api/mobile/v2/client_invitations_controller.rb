class Api::Mobile::V2::ClientInvitationsController < Api::Mobile::V2::ApiController
  before_action :set_invitation, only: [:destroy, :recreate]

  def create
    invitation_builder = ::Api::Web::V1::InvitationBuilder.new(current_user, invitation_params)
    invitation_builder.create_invitation

    if invitation_builder.errors.any?
      render status: 422, json: { errors: invitation_builder.errors }
    else
      render status: 200, json: invitation_builder.invitation, serializer: InvitationSerializer, root: 'invitation'
    end
  end

  def destroy
    if @invitation
      if @invitation.destroy
        render status: 200, json: @invitation.client, serializer: ::Api::Mobile::V2::ClientSerializer, root: 'client'
      else
        render status: 422, json: { errors: @invitation.errors.full_messages }
      end
    else
      render status: 404, json: {}
    end
  end

  def recreate
    @invitation.resend
    render status: 200, json: @invitation, serializer: InvitationSerializer, root: 'invitation'
  end

  private

  def set_invitation
    @invitation = invitations_for_client.first
  end

  def invitations_for_client
    Invitationable::AdvisorToConsumerInvitation.where(
      created_by_user_id: current_user.id,
      client_id: params[:client_id]
    )
  end

  def invitation_params
    params.permit(:client_id,
      invitation: [:email, :phone, :email_invitation, :text_invitation, :text_content])
  end
end
