@Docyt.module "SignInApp.Login", (Login, App, Backbone, Marionette, $, _) ->

  class Login.SignIn extends Marionette.ItemView
    template:  'sign_in/login/sign_in_tmpl'

    ui:
      signUpLink: '.sign-up-link-js'

      emailInput:    '#email'
      passwordInput: '#password'
      signInButton:  '#submit'
      signInForm:    '#sign-in-form'
      confirmEmailAlert: '#confirm-email-alert'

      # validation messages
      invalidCredentials:  '#invalid-credentials'

    events:
      'click @ui.signUpLink':   'navigateToSignUp'
      'submit @ui.signInForm':  'submitSignInForm'
      'click @ui.signInButton': 'submitSignInForm'

    onShow: ->
      @ui.emailInput.focus()
      if @getUrlParamByName('confirmed') == "true" then @ui.confirmEmailAlert.show() else @ui.confirmEmailAlert.hide()

    getUrlParamByName: (name) ->
      results = new RegExp('[\?&]' + name + '=([^&#]*)').exec(window.location.href)
      return if results then results[1] else 0

    submitSignInForm: (e) ->
      e.preventDefault()

      params =
        email:    @ui.emailInput.val()
        password: @ui.passwordInput.val()

      $.ajax
        method: 'POST'
        url: '/api/web/v1/sign_in'
        contentType: "application/json",
        dataType: "json"
        data: JSON.stringify(params)
        success: (response, status) ->
          Docyt.currentAdvisor.updateSelf(response.advisor)
          Backbone.history.navigate("/select_workspace", trigger: true)
        error: (response, status) =>
          @ui.invalidCredentials.show()

    navigateToSignUp: ->
      Backbone.history.navigate("/sign_up", trigger: true)
