@Docyt.module "SignUpApp.ConfirmPincode", (ConfirmPincode, App, Backbone, Marionette, $, _) ->

  class ConfirmPincode.Router extends Marionette.AppRouter
    appRoutes:
      'sign_up/confirm_pincode': 'showSignUpConfirmPincode'
