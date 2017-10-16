@Docyt.module "SignUpApp.Credentials", (Credentials, App, Backbone, Marionette, $, _) ->

  class Credentials.Router extends Marionette.AppRouter
    appRoutes:
      'sign_up': 'showSignUpCredentials'
