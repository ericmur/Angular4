@Docyt.module "SignUpApp.AddPhone", (AddPhone, App, Backbone, Marionette, $, _) ->

  class AddPhone.Router extends Marionette.AppRouter
    appRoutes:
      'sign_up/add_phone': 'showSignUpAddPhone'
