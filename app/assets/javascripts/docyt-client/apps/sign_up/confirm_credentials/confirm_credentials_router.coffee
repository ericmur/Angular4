@Docyt.module "SignUpApp.ConfirmCredentials", (ConfirmCredentials, App, Backbone, Marionette, $, _) ->

  class ConfirmCredentials.Router extends Marionette.AppRouter
    appRoutes:
      'sign_up/confirm_credentials': 'showSignUpConfirmCredentials'
