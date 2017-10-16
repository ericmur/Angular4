@Docyt.module "AdvisorHomeApp.Billing.Layouts", (Layouts, App, Backbone, Marionette, $, _) ->

  class Layouts.Subscription extends Marionette.LayoutView
    template:  'advisor_home/billing/layouts/billing_subscription_layout_tmpl'

    regions:
      billingPlanRegion:       '#billing-subscription-plan-region'
      billingAvailableCreditsRegion:  '#billing-subscription-available-credits-region'
      billingBillHistoryRegion:  '#billing-subscription-bill-history-region'
      billingNextBillRegion:  '#billing-subscription-next-bill-region'
