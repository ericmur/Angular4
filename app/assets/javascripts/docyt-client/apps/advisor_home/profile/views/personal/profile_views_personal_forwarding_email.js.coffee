@Docyt.module 'AdvisorHomeApp.Profile.Views.Personal', (Personal, App, Backbone, Marionette, $, _) ->

  class Personal.ForwardingEmail extends Marionette.ItemView
    template: 'advisor_home/profile/views/personal/forwarding_email_view_tmpl'

    templateHelpers: ->
      emailForwarding: @model.getForwardingEmail()


