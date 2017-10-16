@Docyt.module "SignUpApp.ConfirmPhone", (ConfirmPhone, App, Backbone, Marionette, $, _) ->

  class ConfirmPhone.Controller extends Marionette.Object

    showSignUpConfirmPhone: ->
      if !Docyt.currentAdvisor.get('web_app_is_setup') || !Docyt.currentAdvisor.get('phone_confirmed_at')
        App.mainRegion.show(@getConfirmPhoneView())
      else
        Backbone.history.navigate("/clients", trigger: true)

    getConfirmPhoneView: ->
      new ConfirmPhone.ConfirmPhoneNumber
        model: Docyt.currentAdvisor
