@Docyt.module "SignUpApp.AddPhone", (AddPhone, App, Backbone, Marionette, $, _) ->

  class AddPhone.Controller extends Marionette.Object

    showSignUpAddPhone: ->
      App.mainRegion.show(@getAddPhoneView())

    getAddPhoneView: ->
      new AddPhone.AddPhoneNumber
