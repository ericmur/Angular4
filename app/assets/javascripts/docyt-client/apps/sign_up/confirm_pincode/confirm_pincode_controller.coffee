@Docyt.module "SignUpApp.ConfirmPincode", (ConfirmPincode, App, Backbone, Marionette, $, _) ->

  class ConfirmPincode.Controller extends Marionette.Object

    showSignUpConfirmPincode: ->
      if !Docyt.currentAdvisor.get('web_app_is_set_up') && Docyt.currentAdvisor.get('web_phone_confirmed_at')
        App.mainRegion.show(@getConfirmPincodeView())
      else
        Backbone.history.navigate('/sign_up/confirm_phone', trigger: true)

    getConfirmPincodeView: ->
      new ConfirmPincode.ConfirmPincodeNumber
