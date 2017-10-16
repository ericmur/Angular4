@Docyt.module "SignUpApp.Credentials", (Credentials, App, Backbone, Marionette, $, _) ->

  class Credentials.SignUp extends Marionette.ItemView
    template:  'sign_up/credentials/credentials_tmpl'

    PHONE_REGEXP = /\(?([0-9]{3})\)?([ .-]?)([0-9]{3})\2([0-9]{4})/

    ui:
      signInLink: '.sign-in-link-js'

      phoneInput:    '.phone-input-js'
      emailInput:    '.email-input'
      passwordInput: '.password-input'

      submitButtonWebSignUp:     '.submit-web-sign-up-js'
      submitButtonPhoneSignUp:   '.submit-phone-sign-up-js'
      passwordConfirmationInput: '.password-confirmation-input'

      # validation messages
      emailExists:        '.email-exists'
      emailInvalid:       '.email-invalid'
      phoneInvalid:       '.phone-invalid-js'
      phoneNotFound:      '.phone-not-found-js'
      passwordTooShort:   '.password-too-short'
      passwordsDontMatch: '.password-dont-match'

    events:
      'click @ui.signInLink': 'navigateToSignIn'

      'click @ui.submitButtonWebSignUp':   'submitWebSignUpForm'
      'click @ui.submitButtonPhoneSignUp': 'submitPhoneSignUpForm'

    initialize: ->
      @model = new App.Entities.CurrentAdvisor()

    submitWebSignUpForm: (e) ->
      e.preventDefault()
      @hideAllErrors()

      @model.set('email', @ui.emailInput.val())
      @model.set('password', @ui.passwordInput.val())
      @model.set('password_confirmation', @ui.passwordConfirmationInput.val())

      errors = @model.validate(initial: true)

      if errors.length > 0
        @ui.emailInvalid.show() if _.contains(errors, 'invalid email')
        @ui.passwordTooShort.show() if _.contains(errors, 'please enter more symbols')
        @ui.passwordsDontMatch.show() if _.contains(errors, 'please enter correct password')
      else
        request = @model.save({}, url: '/api/web/v1/sign_up')
        request.fail (response, status) =>
          @ui.emailExists.show() if response.responseJSON.email

        request.success (response, status) =>
          Docyt.currentAdvisor.updateSelf(response.advisor)
          Backbone.history.navigate("/sign_up/add_phone", { trigger: true })

    hideAllErrors: ->
      @ui.emailInvalid.hide()
      @ui.phoneInvalid.hide()
      @ui.passwordTooShort.hide()
      @ui.passwordsDontMatch.hide()

    submitPhoneSignUpForm: (e) ->
      e.preventDefault()
      @hideAllErrors()

      phone = $.trim(@ui.phoneInput.val())

      if phone.length > 0 && PHONE_REGEXP.test(phone)
        @searchAdvisor(phone)
      else
        @ui.phoneInvalid.show()

    showSignUpWithPhoneError: ->
      toastr.error(
        'The account with that phone number already has a web account setup.
        Go ahead and login with your web account credentials',
        'Account already setup.', { timeOut: 10000 }
      )

      @navigateToSignIn()

    navigateToSignIn: ->
      Backbone.history.navigate("/sign_in", { trigger: true })

    searchAdvisor: (phone) ->
      @model.fetch(
        url: '/api/web/v1/advisor/search'
        data:
          search: { phone: phone }
      ).success (response) =>

        if response.advisor.web_app_is_set_up
          @showSignUpWithPhoneError()
        else
          Docyt.currentAdvisor.updateSelf(response.advisor)
          @sendPhoneToken()

      .error (response) =>
        @ui.phoneNotFound.show() if _.isEmpty(response.advisor)

    sendPhoneToken: ->
      Docyt.currentAdvisor.fetch(
        url: '/api/web/v1/advisor/send_phone_token',
        data: { user_id: Docyt.currentAdvisor.id }
      ).done =>
        Backbone.history.navigate("/sign_up/confirm_phone", { trigger: true })
