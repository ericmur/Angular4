@Docyt.module "SignUpApp.ConfirmPhone", (ConfirmPhone, App, Backbone, Marionette, $, _) ->

  class ConfirmPhone.Router extends Marionette.AppRouter
    appRoutes:
      'sign_up/confirm_phone': 'showSignUpConfirmPhone'
