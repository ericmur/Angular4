@Docyt.module 'AdvisorHomeApp.Profile.Views.Security', (Security, App, Backbone, Marionette, $, _) ->

  class Security.Locations extends Marionette.ItemView
    template: 'advisor_home/profile/views/security/locations_view_tmpl'