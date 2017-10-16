@Docyt.module "AdvisorHomeApp.Billing.Layouts", (Layouts, App, Backbone, Marionette, $, _) ->

  class Layouts.Personal extends Marionette.LayoutView
    template:  'advisor_home/billing/layouts/billing_personal_layout_tmpl'

    regions:
      profileNameRegion:            '#advisor-personal-name-region'
      profilePhoneRegion:           '#advisor-personal-phone-region'
