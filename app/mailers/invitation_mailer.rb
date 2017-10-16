class InvitationMailer < ApplicationMailer

  def invitation_email(invitation_id, token)
    @invitation = Invitationable::Invitation.find(invitation_id)
    @email = @invitation.email
    @formated_text = []
    @formated_text = @invitation.text_content.split("\n") if @invitation.text_content.present?
    @token = token
    if @invitation.invitation_type == Invitationable::AdvisorToConsumerInvitation::INVITATION_TYPE
      @sender_name = @invitation.created_by_user.first_name
      @invited_person_name = @invitation.client.name || @invitation.client.user.name
    else
      @invited_person_name = @invitation.group_user.name
    end
    if @invitation.invitation_to_existing_user?
      @subject = I18n.t('emails.subjects.connect_invitation')
    else
      @subject = I18n.t('emails.subjects.invitation')
    end

    @invitation.reload

    if @invitation.pending?
      mail(from: email_address_for(:noreply), to: @email, subject: @subject) do |format|
        format.html
      end
    else
      SlackHelper.ping({channel: "#errors", username: "EmailInvitationBot", message: "Email invitation: (#{@invitation.id}) delivery aborted. Token is blank or already accepted"})
      self.message.perform_deliveries = false
    end
  end
end
