@Docyt.module 'AdvisorHomeApp.Billing.Views.Subscription', (Subscription, App, Backbone, Marionette, $, _) ->

  class Subscription.NextBill extends Marionette.ItemView
    template: 'advisor_home/billing/views/subscription/next_bill_view_tmpl'

    templateHelpers: ->
