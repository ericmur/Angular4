@Docyt.module 'AdvisorHomeApp.Billing.Views.Subscription', (Subscription, App, Backbone, Marionette, $, _) ->

  class Subscription.AvailableCredits extends Marionette.ItemView
    template: 'advisor_home/billing/views/subscription/available_credits_view_tmpl'

    templateHelpers: ->
      clientCategory: @model.get('category_name')
