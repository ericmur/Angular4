@Docyt.module "SignUpApp.CreditCardInfo", (CreditCardInfo, App, Backbone, Marionette, $, _) ->

  class CreditCardInfo.Controller extends Marionette.Object

    showCreditCardInfo: ->
      return @navigateToSignIn() if Docyt.currentAdvisor.isEmpty()

      accountTypes = new Docyt.Entities.ConsumerAccountTypes
      accountTypes.fetch().done =>
        @accType = accountTypes.getType(Docyt.currentAdvisor.get('current_workspace_name'))
      credit = @getCreditCard()
      credit.fetch(url: '/api/web/v1/credit_cards').done =>
        App.mainRegion.show(@getCreditCardInfoView(credit, @accType))

    getCreditCardInfoView: (credit, accType) ->
      new CreditCardInfo.AddCreditCardInfo
        model: credit
        accType: accType

    navigateToSignIn: ->
      Backbone.history.navigate("/sign_in", trigger: true)

    getCreditCard: ->
      new Docyt.Entities.CreditCard
