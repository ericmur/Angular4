@Docyt.module "SignUpApp.Credentials", (Credentials, App, Backbone, Marionette, $, _) ->

  class Credentials.Controller extends Marionette.Object

    showSignUpCredentials: ->
      if Docyt.currentAdvisor.isEmpty() || !Docyt.currentAdvisor.get('web_app_is_set_up')
        App.mainRegion.show(@getSignUpView())
      else
        Backbone.history.navigate('/clients', trigger: true)

    getSignUpView: ->
      new Credentials.SignUp
