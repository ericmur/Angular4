@Docyt.module "AdvisorHomeApp.Clients.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.HeaderMenu extends Marionette.ItemView
    className: 'client__docs'
    template: 'advisor_home/clients/show/details/clients_details_header_menu_tmpl'

    ui:
      inviteClientButton: '#invite-client'
      invitedText: "#invited-text"

    events:
      'click @ui.inviteClientButton': 'openInviteClientModal'

    onRender: ->
      unless @isAlreadyInvited()
        @ui.invitedText.hide()
      else
        @ui.invitedText.text(@setInvitedDaysAgoText())

    onShow: ->
      @isRendered = true

    openInviteClientModal: ->
      if @isAlreadyInvited()
        @destroyInvitation()
      else
        @createModal()

    destroyInvitation: ->
      invite = new Docyt.Entities.Invitation(id: @model.get('invitation').id)
      invite.destroy(url: "/api/web/v1/clients/#{@model.get('id')}/invitations/#{invite.get('id')}").success =>
        @model.set("invitations_count", 0)
        @ui.invitedText.empty().hide()
        @ui.inviteClientButton.text(@setButtonText())
      .error =>
        toastr.error('Invitation removal failed. Please try again.', 'Something went wrong.')

    createModal: ->
      modalView = new Docyt.AdvisorHomeApp.Clients.Show.Details.InviteClientModal(model: @model)
      Docyt.modalRegion.show(modalView)
      modalView.on "change:invite:button:text", =>
        @ui.inviteClientButton.text(@setButtonText())

    templateHelpers: ->
      avatarUrl: @getClientAvatarUrl()
      group_users: @model.get('group_users')
      groupUsersCountText: @groupUsersCountText()
      groupUserAvatarUrl: @groupUserAvatarUrl
      inviteButtonTextContent: @setButtonText()
      isConnected: @model.isConnected()

    getClientAvatarUrl: ->
      return unless @model.has('avatar')
      s3_object_key = @model.get('avatar').s3_object_key
      "https://#{configData.bucketName}.s3.amazonaws.com/#{s3_object_key}"

    groupUsersCountText: ->
      gUsers = @model.get('group_users')
      if gUsers
        if gUsers.length > 1
          return "+#{gUsers.length} family members"
        else if gUsers.length == 1
          return "+1 family member"
        else
          return ""
      else
        return ""

    groupUserAvatarUrl: (gUser) ->
      if gUser.avatar
        s3_object_key = gUser.avatar.s3_object_key
        "https://#{configData.bucketName}.s3.amazonaws.com/#{s3_object_key}"

    setButtonText: ->
      return @getButtonContent() if @isAlreadyInvited()
      "Invite #{@model.get('parsed_fullname').split(' ')[0]}"

    setInvitedDaysAgoText: ->
      if @model.get('sended_invitation_days_ago') == 0 then "Invited today" else "Invited #{@model.get('sended_invitation_days_ago')} days ago"

    getButtonContent: ->
      if @isRendered
        @ui.invitedText.show()
        @ui.invitedText.text(@setInvitedDaysAgoText())
      "Cancel invite"

    isAlreadyInvited: ->
      @model.get('invitations_count') > 0
