@Docyt.module "SignUpApp.ConfirmEmail", (ConfirmEmail, App, Backbone, Marionette, $, _) ->

  class ConfirmEmail.Controller extends Marionette.Object

    showSignUpConfirmEmail: ->
      if Docyt.currentAdvisor.get('email_confirmed_at')
        Backbone.history.navigate("/clients", trigger: true)
      else
        App.mainRegion.show(@getConfirmEmailView())

    getConfirmEmailView: ->
      new ConfirmEmail.ConfirmEmailView
