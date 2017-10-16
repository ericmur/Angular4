@Docyt.module "SignInApp.Login", (Login, App, Backbone, Marionette, $, _) ->

  class Login.Controller extends Marionette.Object

    showSignIn: ->
      if Docyt.currentAdvisor.isEmpty() || !Docyt.currentAdvisor.get('web_app_is_set_up')
        App.mainRegion.show(@getSignInView())
      else
        Backbone.history.navigate('/select_workspace', { trigger: true })

    getSignInView: ->
      new Login.SignIn()
