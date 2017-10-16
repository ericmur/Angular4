@Docyt.module "SignUpApp.ConfirmEmail", (ConfirmEmail, App, Backbone, Marionette, $, _) ->

  class ConfirmEmail.Router extends Marionette.AppRouter
    appRoutes:
      'sign_up/confirm_email': 'showSignUpConfirmEmail'
