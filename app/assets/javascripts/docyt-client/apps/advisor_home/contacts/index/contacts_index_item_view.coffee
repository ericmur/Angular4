@Docyt.module "AdvisorHomeApp.Contacts.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ContactView extends Marionette.ItemView
    template:  'advisor_home/contacts/index/contacts_index_item_tmpl'

    ui:
      addContact:     '.add-contact-js'
      contactName:    '.contacts__contact-name-text'
      invitationBtn:  '.invitation-btn-js'
      invitationInfo: '.invitation-info-js'

    events:
      'click @ui.addContact':    'showAddContactModal'
      'click @ui.invitationBtn': 'showInvitationModal'

    onRender: ->
      @setColorName()

    templateHelpers: ->
      avatarUrl:    @model.getAvatarUrl()
      hasInvite:    @model.get('invitation')
      isDefault:    @model.get('default')
      isConnected:  @model.get('user_id')

      invitationBtnText:  @setInvitationBtnText()
      invitationInfoText: @setInvitationInfoText()

    setInvitationBtnText: ->
      return 'Cancel Invitation' if @model.get('invitation')

      'Send Invitation'

    setInvitationInfoText: ->
      return "Invited today" if @model.get('invitation_sended_days_ago') == 0

      "Invited #{@model.get('invitation_sended_days_ago')} days ago"

    showInvitationModal: ->
      if @model.get('invitation')
        @destroyInvitation()
      else
        @createInvitation()

    createInvitation: ->
      modalView = new Docyt.AdvisorHomeApp.Clients.Show.Details.InviteClientModal(model: @model)
      Docyt.modalRegion.show(modalView)

      modalView.on("change:invite:button:text", =>
        if @model.get('invitation')
          @model.set('invitation_sended_days_ago', 0)
          @render()
      )

    destroyInvitation: ->
      invite = new Docyt.Entities.Invitation(id: @model.get('invitation').id)
      invite.destroy(url: "/api/web/v1/clients/#{@model.get('id')}/invitations/#{invite.get('id')}").success =>
        @model.unset("invitation")
        @render()
      .error =>
        toastr.error('Invitation removal failed. Please try again.', 'Something went wrong.')

    setColorName: ->
      return if @model.get('default') || @model.get('user_id')

      @ui.contactName.addClass('in-grey-500')

    showAddContactModal: ->
      return unless @model.get('default')

      modalView = new Docyt.AdvisorHomeApp.Clients.Index.CreateClientModal
        model: new Docyt.Entities.Contact(type: 'Contact')

      Docyt.modalRegion.show(modalView)
