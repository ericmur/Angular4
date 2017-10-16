@Docyt.module 'AdvisorHomeApp.Billing.Views.Subscription', (Subscription, App, Backbone, Marionette, $, _) ->

  class Subscription.BillHistory extends Marionette.ItemView
    template: 'advisor_home/billing/views/subscription/bill_history_view_tmpl'

    templateHelpers: ->
      clientCategory: @model.get('category_name')
