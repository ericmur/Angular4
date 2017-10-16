@Docyt.module "AdvisorHomeApp.Profile.Layouts", (Layouts, App, Backbone, Marionette, $, _) ->

  class Layouts.Security extends Marionette.LayoutView
    template:  'advisor_home/profile/layouts/profile_security_layout_tmpl'

    regions:
      profileAuthenticationRegion:  '#advisor-security-authentication-region'
      profileEncryptionRegion:      '#advisor-security-encryption-region'
      profileLocationsRegion:       '#advisor-security-locations-region'