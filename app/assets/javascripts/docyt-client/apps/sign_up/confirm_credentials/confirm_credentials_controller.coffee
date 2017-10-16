@Docyt.module "SignUpApp.ConfirmCredentials", (ConfirmCredentials, App, Backbone, Marionette, $, _) ->

  class ConfirmCredentials.Controller extends Marionette.Object

    showSignUpConfirmCredentials: ->
      if Docyt.currentAdvisor.get('valid_pin')
        App.mainRegion.show(@getConfirmCredentialsView())
      else
        Backbone.history.navigate('/sign_up/confirm_pincode', trigger: true)

    getConfirmCredentialsView: ->
      new ConfirmCredentials.ConfirmCredentialsView
