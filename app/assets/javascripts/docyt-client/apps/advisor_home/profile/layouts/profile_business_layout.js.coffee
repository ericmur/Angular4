@Docyt.module "AdvisorHomeApp.Profile.Layouts", (Layouts, App, Backbone, Marionette, $, _) ->

  class Layouts.Business extends Marionette.LayoutView
    template:  'advisor_home/profile/layouts/profile_business_layout_tmpl'

    regions:
      profileTypeRegion:  '#advisor-business-type-region'
      profileAddressRegion:       '#advisor-business-address-region'