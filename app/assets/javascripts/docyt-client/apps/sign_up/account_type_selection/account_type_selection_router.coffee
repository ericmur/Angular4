@Docyt.module "SignUpApp.AccountTypeSelection", (AccountTypeSelection, App, Backbone, Marionette, $, _) ->

  class AccountTypeSelection.Router extends Marionette.AppRouter
    appRoutes:
      'sign_up/account_type_selection': 'showAccountTypeSelection'
