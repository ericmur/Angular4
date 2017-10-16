@Docyt.module "AdvisorHomeApp.Billing", (Billing, App, Backbone, Marionette, $, _) ->

  class Billing.Controller extends Marionette.Object

    showBillingPage: ->
      return @navigateToSignIn() if Docyt.currentAdvisor.isEmpty()

      subscription = new Docyt.Entities.Subscriptions
      subscription.fetch().done =>
        @subscription = subscription

      accountTypes = new Docyt.Entities.ConsumerAccountTypes
      credit = new Docyt.Entities.CreditCard

      billingLayout = @getBillingLayoutView()
      App.mainRegion.show(billingLayout)

      currentAdvisor = @getCurrentAdvisor()

      profilePersonalLayout = @getBillingPersonalLayout()
      billingLayout.profilePersonalRegion.show(profilePersonalLayout)
      credit.fetch(url: '/api/web/v1/credit_cards').done =>
        @buildProfilePersonalLayout(profilePersonalLayout, currentAdvisor, credit)

      billingSubscriptionLayout = @getBillingSubscriptionLayout()
      billingLayout.billingSubscriptionRegion.show(billingSubscriptionLayout)
      accountTypes.fetch().done =>
        @buildBillingSubscriptionLayout(billingSubscriptionLayout, currentAdvisor, accountTypes, @subscription)

    getCurrentAdvisor: ->
      Docyt.currentAdvisor

    getBillingLayoutView: ->
      new Billing.Layout()

    getBillingPersonalLayout: ->
      new Billing.Layouts.Personal()

    getBillingSubscriptionLayout: ->
      new Billing.Layouts.Subscription()

    buildProfilePersonalLayout: (profilePersonalLayout, currentAdvisor, credit) ->
      personalNameView = @getPersonalNameView(credit)
      profilePersonalLayout.profileNameRegion.show(personalNameView)

      personalPhoneView = @getPersonalPhoneView(currentAdvisor)
      profilePersonalLayout.profilePhoneRegion.show(personalPhoneView)

    getPersonalNameView: (credit) ->
      new Billing.Views.Personal.CreditCard({ model: credit })

    getPersonalPhoneView: (currentAdvisor) ->
      new Billing.Views.Personal.Tax({ model: currentAdvisor })

    buildBillingSubscriptionLayout: (billingSubscriptionLayout, currentAdvisor, accType, subscription) ->
      subscriptionAvailableCreditsView = @getSubscriptionAvailableCreditsView(currentAdvisor)
      billingSubscriptionLayout.billingAvailableCreditsRegion.show(subscriptionAvailableCreditsView)

      subscriptionBillHistoryView = @getSubscriptionBillHistoryView(currentAdvisor)
      billingSubscriptionLayout.billingBillHistoryRegion.show(subscriptionBillHistoryView)

      subscriptionNextBillView = @getSubscriptionNextBillView(subscription)
      billingSubscriptionLayout.billingNextBillRegion.show(subscriptionNextBillView)

      subscriptionPlanView = @getSubscriptionPlanView(subscription, accType)
      billingSubscriptionLayout.billingPlanRegion.show(subscriptionPlanView)

    getSubscriptionAvailableCreditsView: (currentAdvisor) ->
      new Billing.Views.Subscription.AvailableCredits({ model: currentAdvisor })

    getSubscriptionBillHistoryView: (currentAdvisor) ->
      new Billing.Views.Subscription.BillHistory({ model: currentAdvisor })

    getSubscriptionNextBillView: (subscription) ->
      new Billing.Views.Subscription.NextBill({ model: subscription })

    getSubscriptionPlanView: (subscription, accType) ->
      new Billing.Views.Subscription.Plan({ model: subscription, accType: accType })

    navigateToSignIn: ->
      Backbone.history.navigate('/sign_in', trigger: true)
