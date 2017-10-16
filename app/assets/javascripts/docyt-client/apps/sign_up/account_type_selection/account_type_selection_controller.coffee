@Docyt.module "SignUpApp.AccountTypeSelection", (AccountTypeSelection, App, Backbone, Marionette, $, _) ->

  class AccountTypeSelection.Controller extends Marionette.Object

    showAccountTypeSelection: ->
      return @navigateToSignIn() if Docyt.currentAdvisor.isEmpty()

      accountTypes = @getConsumerAccountTypes()
      accountTypes.fetch(url: '/api/web/v1/consumer_account_types').done =>
        App.mainRegion.show(@getAccountTypeSelectionView(accountTypes))

    getAccountTypeSelectionView: (accountTypes) ->
      new AccountTypeSelection.SelectAccountType
        model: Docyt.currentAdvisor
        accountTypes: accountTypes

    navigateToSignIn: ->
      Backbone.history.navigate("/sign_in", trigger: true)

    getConsumerAccountTypes: ->
      new Docyt.Entities.ConsumerAccountTypes
