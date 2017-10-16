@Docyt.module "AdvisorHomeApp.Clients.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.CreateClientModal extends Marionette.ItemView
    template: 'advisor_home/clients/index/clients_index_create_client_modal_tmpl'

    ui:
      emailInput: '#email'
      nameInput:  '#name'
      phoneInput: '#phone'

      emailInvitationCheckbox: '#by-email'
      phoneInvitationCheckbox: '#by-text'

      submitButton: '#create-client'
      cancel:       '.cancel'

      # validation messages
      nameInvalid:  '#name-invalid'
      nameExists:   '#name-exists'
      emailExists:  '#email-exists'
      emailInvalid: '#email-invalid'
      phoneExists:  '#phone-exists'
      phoneInvalid: '#phone-invalid'
      groupInvalid: '.group-invalid-js'

      phoneInviteWithoutPhone: '#phone-invite-error'
      emailInviteWithoutEmail: '#email-invite-error'

      fullnameNotSet: '#fullname-invite-error'

      groupTypesField: '.group-types-input-js'

    events:
      'click @ui.submitButton': 'submitCreateClientForm'
      'click @ui.cancel':       'closeModal'

    initialize: ->
      Docyt.vent.on('standard:groups:loaded', @setAutocompleteOptions)

    onDestroy: ->
      Docyt.vent.off('standard:groups:loaded')

    onRender: ->
      if @model.get('type') == 'Contact'
        @getGroupTypes()
        @initAutocomplete()

    closeModal: ->
      @destroy()

    initAutocomplete: ->
      selectizeSelect = @ui.groupTypesField.selectize(
        valueField: 'id'
        labelField: 'name'
        create:  false
        render:
          item: (data, escape) =>
            @selectizeHtml(data)
          option: (data, escape) =>
            @selectizeHtml(data)
        onChange: (value) =>
          @model.set(standard_group_id: value)
      )
      @selectize = selectizeSelect[0].selectize

    selectizeHtml: (data) ->
      "<div class=\"item\">#{data.name}</div>"

    getGroupTypes: ->
      Docyt.vent.trigger('show:spinner')
      standardGroups = new Docyt.Entities.StandardGroups

      standardGroups.fetch().done =>
        Docyt.vent.trigger('hide:spinner')
        Docyt.vent.trigger('standard:groups:loaded', standardGroups)
      .error =>
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Load group types failed. Please try later.', 'Something went wrong.')

    setAutocompleteOptions: (standardGroups) =>
      @selectize.addOption(standardGroups.toJSON())

    submitCreateClientForm: ->
      inviteByEmail = @ui.emailInvitationCheckbox.is(':checked')
      inviteByPhone = @ui.phoneInvitationCheckbox.is(':checked')

      if @createFormValid()
        @model.set(
          name:  @ui.nameInput.val()
          email: @ui.emailInput.val()
          phone: @ui.phoneInput.val()
        )

        @addIfInvitation(inviteByPhone, inviteByEmail)

        @model.save().always (response) =>
          # here we check if a server-side validation passed
          if response.responseJSON
            _.every([@noClientValidationErrors(response.responseJSON),
                     @noInvitationValidationErrors(response.responseJSON)])
          else
            Docyt.vent.trigger('client:created', @model)
            @destroy()

    # validations
    createFormValid: ->
      @clearAllValidationMessages()
      true if _.every([@validateName(), @validateEmail(), @validatePhone(), @validateGroupType()])

    clearAllValidationMessages: ->
      _.invoke([@ui.emailInvalid, @ui.emailExists, @ui.phoneExists, @ui.nameInvalid,
                @ui.phoneInvalid, @ui.emailInviteWithoutEmail, @ui.fullnameNotSet,
                @ui.phoneInviteWithoutPhone, @ui.groupInvalid],'hide')

    validateEmail: ->
      return true if !@ui.emailInvitationCheckbox.is(':checked') && $.trim(@ui.emailInput.val()).length == 0

      if (/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(@ui.emailInput.val()))
        true
      else
        @ui.emailInvalid.show()
        false

    validateName: ->
      if $.trim(@ui.nameInput.val()).length > 0
        true
      else
        @ui.nameInvalid.show()
        false

    validatePhone: ->
      return true if !@ui.phoneInvitationCheckbox.is(':checked') && $.trim(@ui.phoneInput.val()).length == 0

      if $.trim(@ui.phoneInput.val()).length == 10
        true
      else
        @ui.phoneInvalid.show()
        false

    validateInvitations: ->
      true if _.every([@validateEmailInvitation(), @validatePhoneInvitation()])

    validateEmailInvitation: ->
      if @ui.emailInvitationCheckbox.is(':checked') && $.trim(@ui.emailInput.val()).length > 0
        true
      else if @ui.emailInvitationCheckbox.is(':checked') && $.trim(@ui.emailInput.val()).length == 0
        @ui.emailInviteWithoutEmail.show()
        false
      else
        true

    validatePhoneInvitation: ->
      if @ui.phoneInvitationCheckbox.is(':checked') && $.trim(@ui.phoneInput.val()).length > 0
        true
      if @ui.phoneInvitationCheckbox.is(':checked') && $.trim(@ui.phoneInput.val()).length == 0
        @ui.phoneInviteWithoutPhone.show()
        false
      else
        true

    noClientValidationErrors: (response) ->
      true if _.every([@noPhoneValidationErrors(response), @noEmailValidationErrors(response)])

    noInvitationValidationErrors: (response) ->
      @noUnverifiedFullnameEmailErrors(response)

    noPhoneValidationErrors: (response) ->
      errors = response.client_errors

      if errors && _.contains(errors, 'Phone is an invalid number')
        @ui.phoneInvalid.show()
        false
      else if errors && _.contains(errors, 'Phone can only be associated once with the same advisor')
        @ui.phoneExists.show()
        false
      else
        true

    noEmailValidationErrors: (response) ->
      errors = response.client_errors

      if errors && _.contains(errors, 'is an invalid email')
        @ui.emailInvalid.show()
        false
      else if errors and _.contains(errors, 'Email can only be associated once with the same advisor')
        @ui.emailExists.show()
        false
      else
        true

    noUnverifiedFullnameEmailErrors: (response) ->
      errors = response.invitation_errors

      if errors && _.contains(errors, I18n.t('errors.invitation.require_fullname'))
        @ui.fullnameNotSet.show()
        false
      else
        true

    validateGroupType: ->
      return true if @model.get('type') == 'Client'

      if @model.get('standard_group_id')
        true
      else
        @ui.groupInvalid.show()
        false

    addIfInvitation: (inviteByPhone, inviteByEmail) ->
      if inviteByPhone || inviteByEmail
        invitation =
          email: @model.get('email')
          phone: @model.get('phone')
          text_invitation:  inviteByPhone
          email_invitation: inviteByEmail

        @model.set('invitation', invitation)

      @model
