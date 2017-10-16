@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.UnconnectedClientChatItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/messages/clients_messages_unconnected_tmpl'

    ui:
      invitedText:        '#invited-text'
      inviteClientButton: '#invite-client'

    events:
      'click @ui.inviteClientButton': 'openInviteClientModal'

    templateHelpers: ->
      inviteButtonTextContent: @setButtonText()

    onRender: ->
      if @isAlreadyInvited()
        @ui.invitedText.text(@setInvitedDaysAgoText())
      else
        @ui.invitedText.hide()

    openInviteClientModal: ->
      if @isAlreadyInvited()
        @destroyInvitation()
      else
        @createModal()

    isAlreadyInvited: ->
      @model.get('invitations_count') > 0

    setInvitedDaysAgoText: ->
      if @model.get('sended_invitation_days_ago') == 0 then "Invited today" else "Invited #{@model.get('sended_invitation_days_ago')} days ago"

    destroyInvitation: ->
      invite = new Docyt.Entities.Invitation(id: @model.get('invitation').id)
      invite.destroy(url: "/api/web/v1/clients/#{@model.get('id')}/invitations/#{invite.get('id')}").success =>
        @model.set("invitations_count", 0)
        @ui.invitedText.empty().hide()
        @ui.inviteClientButton.text(@setButtonText())
      .error =>
        toastr.error('Invitation removal failed. Please try again.', 'Something went wrong.')

    createModal: ->
      modalView = new Docyt.AdvisorHomeApp.Clients.Show.Details.InviteClientModal({ model: @model })
      Docyt.modalRegion.show(modalView)

      modalView.on "change:invite:button:text", =>
        @ui.inviteClientButton.text(@setButtonText())
        @ui.invitedText.text(@setInvitedDaysAgoText())
        @ui.invitedText.show()

    setButtonText: ->
      return "Cancel invite" if @isAlreadyInvited()
      "Invite #{@model.get('parsed_fullname').split(' ')[0]}"
