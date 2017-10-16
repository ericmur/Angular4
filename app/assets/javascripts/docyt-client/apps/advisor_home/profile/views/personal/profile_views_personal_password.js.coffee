@Docyt.module 'AdvisorHomeApp.Profile.Views.Personal', (Personal, App, Backbone, Marionette, $, _) ->

  class Personal.Password extends Marionette.ItemView
    template: 'advisor_home/profile/views/personal/password_view_tmpl'

    ui:
      form:                       '#form-personal-password'
      currentPasswordInput:       '#input-personal-current-password'
      passwordInput:              '#input-personal-password'
      passwordConfirmationInput:  '#input-personal-password-confirmation'
      submitButton:               '#submit-personal-password'

      # validation messages
      currentPasswordInvalid:   '#current-password-invalid'
      currentPasswordTooShort:  '#current-password-too-short'
      newPasswordTooShort:      '#new-password-too-short'
      newPasswordsDontMatch:    '#new-password-dont-match'

    events:
      'submit @ui.form':        'submitForm'
      'click @ui.submitButton': 'submitForm'

    templateHelpers: ->
      passwordUpdatedAt: @getPasswordUpdateTimeAgo()

    initialize: ->
      @listenTo(@model, 'change:password_updated_at', @render)

    submitForm: (e) ->
      e.preventDefault()

      return unless @passwordFormValid()

      @model.set(
        current_password:       @ui.currentPasswordInput.val(),
        password:               @ui.passwordInput.val(),
        password_confirmation:  @ui.passwordConfirmationInput.val()
      )

      @model.updateCurrentAdvisor().error (response) =>
        if response.responseJSON.password
          @ui.currentPasswordInvalid.show()

    passwordFormValid: ->
      true if _.every([@validatePassword(), @validateNewPassword()])

    validatePassword: ->
      @ui.currentPasswordInvalid.hide()
      password = @ui.currentPasswordInput.val()
      @validatePasswordLength(password, @ui.currentPasswordTooShort)

    validateNewPassword: ->
      newPassword = @ui.passwordInput.val()
      true if _.every([
                        @validatePasswordLength(newPassword, @ui.newPasswordTooShort),
                        @validatePasswordConfirmation()
                      ])

    validatePasswordLength: (password, errorElement) ->
      if password.length < 8
        errorElement.show()
        false
      else
        errorElement.hide()
        true

    validatePasswordConfirmation: ->
      password = @ui.passwordInput.val()
      passwordConfirmation = @ui.passwordConfirmationInput.val()
      if password != passwordConfirmation
        @ui.newPasswordsDontMatch.show()
        false
      else
        @ui.newPasswordsDontMatch.hide()
        true

    getPasswordUpdateTimeAgo: ->
      if @model.has('password_updated_at')
        "Updated " + $.timeago(@model.get('password_updated_at'))
      else
        'Has never been updated'
