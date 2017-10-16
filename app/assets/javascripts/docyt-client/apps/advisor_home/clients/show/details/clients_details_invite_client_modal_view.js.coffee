@Docyt.module "AdvisorHomeApp.Clients.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.InviteClientModal extends Marionette.ItemView
    template: 'advisor_home/clients/show/details/clients_details_invite_client_modal_tmpl'

    ui:
      invitationInput: '#text'

      cancel:       '.cancel'
      submitButton: '#create-invitation'

      fullnameNotSet:       '#fullname-invite-error'
      checkBoxesError:      '#checkbox-invite-error'
      checkBoxesPhoneError: '#checkbox-invite-no-phone-error'
      checkBoxesEmailError: '#checkbox-invite-no-email-error'
      invalidTextContent:   '#invite-text-invalid'

      textInvitationCheckbox:  '#by-text'
      emailInvitationCheckbox: '#by-email'

    events:
      'click @ui.cancel':       'closeModal'
      'click @ui.submitButton': 'submitCreateInvitationForm'

    templateHelpers: ->
      clientName: @model.get('parsed_fullname').split(' ')[0]
      advisorName: App.currentAdvisor.get('full_name').split(' ')[0]
      advisorPhone: App.currentAdvisor.get('phone_normalized')

    closeModal: ->
      @trigger("change:invite:button:text")
      @destroy()

    submitCreateInvitationForm: ->
      @hideAllErrors()
      textContent = @ui.invitationInput.val().replace(/\s\s+/g, ' ')

      if textContent.length > 0 && (@isTextInviteChecked() || @isEmailInviteChecked())
        invitation = new Docyt.Entities.Invitation(
          email: @model.get('email')
          phone: @model.get('phone')
          client_id:   @model.get('id')
          client_type: @model.get('type')
          text_content: @ui.invitationInput.val()
          text_invitation: @isTextInviteChecked()
          email_invitation: @isEmailInviteChecked()
        )

        invitation.save({}, url: "/api/web/v1/clients/#{@model.get('id')}/invitations").always (response) =>
          if response.invitation_errors && _.contains(response.invitation_errors, I18n.t('errors.invitation.require_fullname'))
            @ui.fullnameNotSet.show()
          else
            @model.set("invitation", response.invitation)
            @model.set("invitations_count", 1)
            @model.set("sended_invitation_days_ago", 0)
            @trigger("change:invite:button:text")
            @destroy()
      else
        @checkTextContent(textContent)
        @verifyCheckBoxes()
        @verifyCheckBoxesPhonePresent() if @ui.textInvitationCheckbox.is(":checked")
        @verifyCheckBoxesEmailPresent() if @ui.emailInvitationCheckbox.is(":checked")

    checkTextContent: (textContent) ->
      @ui.invalidTextContent.show() if _.isEmpty(textContent)

    verifyCheckBoxesPhonePresent: ->
      @ui.checkBoxesPhoneError.show() unless @isClientHavePhoneNumber()

    verifyCheckBoxesEmailPresent: ->
      @ui.checkBoxesEmailError.show() unless @isClientHaveEmail()

    verifyCheckBoxes: ->
      @ui.checkBoxesError.show() unless @isTextInviteChecked() && @isEmailInviteChecked()

    isTextInviteChecked: ->
      return @ui.textInvitationCheckbox.is(':checked') if @isClientHavePhoneNumber()
      false

    isEmailInviteChecked: ->
      return @ui.emailInvitationCheckbox.is(':checked') if @isClientHaveEmail()
      false

    isClientHaveEmail: ->
      @model.has("email") && @model.get("email") != ""

    isClientHavePhoneNumber: ->
      @model.has("phone_normalized") && @model.get("phone_normalized") != ""

    hideAllErrors: ->
      @ui.fullnameNotSet.hide()
      @ui.checkBoxesError.hide()
      @ui.checkBoxesPhoneError.hide()
      @ui.checkBoxesEmailError.hide()
      @ui.invalidTextContent.hide()
