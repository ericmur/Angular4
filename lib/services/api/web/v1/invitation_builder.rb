class Api::Web::V1::InvitationBuilder

  def initialize(advisor, params)
    @params  = params
    @advisor = advisor

    @invitee_params    = params.except('invitation')
    @invitation_params = params['invitation']
  end

  def create_invitation
    build_invitation
    save_invitation
  end

  def build_invitation
    @invitation = Invitationable::AdvisorToConsumerInvitation.new(@invitation_params)
    @invitation.invitee_type = 'Consumer'
    set_invitee
    @invitation.created_by_user = @advisor

    @invitation
  end

  def errors
    @invitation.errors.full_messages if @invitation.errors
  end

  def invitation
    @invitation
  end

  private

  def save_invitation
    if @invitation && @invitation.errors.blank?
      @invitation.save
    end
  end

  def set_invitee
    if @invitee_params[:client_type] == GroupUser.name.to_s
      @invitation.group_user_id = @invitee_params[:client_id]
    else
      @invitation.client_id = @invitee_params[:client_id]
    end
  end

end
