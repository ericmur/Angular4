@Docyt.module "AdvisorHomeApp.Profile.Layouts", (Layouts, App, Backbone, Marionette, $, _) ->

  class Layouts.Personal extends Marionette.LayoutView
    template:  'advisor_home/profile/layouts/profile_personal_layout_tmpl'

    regions:
      profileAvatarRegion:          '#advisor-personal-avatar-region'
      profileNameRegion:            '#advisor-personal-name-region'
      profileEmailRegion:           '#advisor-personal-email-region'
      profilePasswordRegion:        '#advisor-personal-password-region'
      profilePhoneRegion:           '#advisor-personal-phone-region'
      profileForwardingEmailRegion: '#advisor-personal-forwarding-email-region'