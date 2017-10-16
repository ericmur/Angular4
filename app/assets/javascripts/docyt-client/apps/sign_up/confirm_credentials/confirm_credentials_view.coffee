@Docyt.module "SignUpApp.ConfirmCredentials", (ConfirmCredentials, App, Backbone, Marionette, $, _) ->

  class ConfirmCredentials.ConfirmCredentialsView extends Marionette.ItemView
    template:  'sign_up/confirm_credentials/confirm_credentials_tmpl'

    ui:
      changeEmail:  '.change-email-link-js'
      submitButton: '.submit-credentials-js'

      emailInput:      '.email-input-js'
      emailBlockInfo:  '.email-info-block-js'
      emailBlockInput: '.email-block-input-js'

      passwordInput:        '.password-input-js'
      passwordConfirmInput: '.password-confirmation-input-js'

      existsEmail:        '.email-exists-js'
      invalidEmail:       '.email-invalid-js'
      passwordTooShort:   '.password-too-short-js'
      passwordsDontMatch: '.password-dont-match-js'

    events:
      'click @ui.changeEmail':  'displayEmailInput'
      'click @ui.submitButton': 'submitCredentials'

    initialize: ->
      @changeEmail = false

    onRender: ->
      @ui.emailBlockInput.hide() if Docyt.currentAdvisor.get('email')

    displayEmailInput: ->
      @changeEmail = true
      @ui.emailBlockInput.show()
      @ui.emailBlockInfo.hide()

    submitCredentials: ->
      @hideAllErrors()

      @setupAttributes()

      errors = Docyt.currentAdvisor.validate(initial: true)

      if errors.length > 0
        @showErrors(errors)
      else
        @sendData()

    sendData: ->
      Docyt.currentAdvisor.save({}, url: '/api/web/v1/advisor/confirm_credentials').success =>
        Docyt.currentAdvisor.signOut()
        toastr.success('Sign In with the account you have just setup', 'Successfully.')
      .error (response) =>
        @ui.existsEmail.show() if response.responseJSON.email

    hideAllErrors: ->
      @ui.existsEmail.hide()
      @ui.invalidEmail.hide()
      @ui.passwordTooShort.hide()
      @ui.passwordsDontMatch.hide()

    showErrors: (errors) ->
      @ui.invalidEmail.show() if Docyt.currentAdvisor.validateEmail(Docyt.currentAdvisor.get('unverified_email'))
      @ui.passwordTooShort.show() if _.contains(errors, 'please enter more symbols')
      @ui.passwordsDontMatch.show() if _.contains(errors, 'please enter correct password')

    setupAttributes: ->
      if @changeEmail || !Docyt.currentAdvisor.get('email')
        unverified_email = $.trim(@ui.emailInput.val())

      Docyt.currentAdvisor.set(
        unverified_email: unverified_email,
        password: $.trim(@ui.passwordInput.val()),
        password_confirmation: $.trim(@ui.passwordConfirmInput.val())
      )
