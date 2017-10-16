@Docyt.module 'AdvisorHomeApp.Profile.Views.Security', (Security, App, Backbone, Marionette, $, _) ->

  class Security.Encryption extends Marionette.ItemView
    template: 'advisor_home/profile/views/security/encryption_view_tmpl'