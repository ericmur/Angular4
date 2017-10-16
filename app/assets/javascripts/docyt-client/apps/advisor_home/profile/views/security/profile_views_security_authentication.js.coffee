@Docyt.module 'AdvisorHomeApp.Profile.Views.Security', (Security, App, Backbone, Marionette, $, _) ->

  class Security.Authentication extends Marionette.ItemView
    template: 'advisor_home/profile/views/security/authentication_view_tmpl'