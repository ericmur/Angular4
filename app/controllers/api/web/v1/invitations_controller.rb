class Api::Web::V1::InvitationsController < Api::Web::V1::ApiController
  before_action :set_invitation, only: [:destroy]

  def create
    invitation = Api::Web::V1::InvitationBuilder.new(current_advisor, invitation_params)
    invitation.create_invitation

    if invitation.errors.any?
      render status: 422, json: invitation.errors, root: :invitation_errors
    else
      render status: 201, json: invitation
    end
  end

  def destroy
    if @invitation
      @invitation.destroy
      render status: 200, json: @invitation
    else
      render status: 404, json: {}
    end
  end

  private

  def set_invitation
    @invitation = Invitationable::Invitation.find_by(id: params[:id])
  end

  def invitation_params
    params.permit(:client_id, :client_type,
      invitation: [:email, :phone, :email_invitation, :text_invitation, :text_content])
  end
end
