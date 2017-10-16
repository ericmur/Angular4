@Docyt.module "SignInApp.Login", (Login, App, Backbone, Marionette, $, _) ->

  class Login.Router extends Marionette.AppRouter
    appRoutes:
      'sign_in': 'showSignIn'
