class TextInvitationJob < ActiveJob::Base
  queue_as :default

  def perform(invitation_id)
    @invitation = Invitationable::Invitation.find_by_id(invitation_id)
    if @invitation
      @invitation.deliver_text_invitation
    end
  end
end
