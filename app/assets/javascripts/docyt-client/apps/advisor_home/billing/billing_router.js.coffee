@Docyt.module "AdvisorHomeApp.Billing", (Billing, App, Backbone, Marionette, $, _) ->

  class Billing.Router extends Marionette.AppRouter
    appRoutes:
      'billing': 'showBillingPage'
