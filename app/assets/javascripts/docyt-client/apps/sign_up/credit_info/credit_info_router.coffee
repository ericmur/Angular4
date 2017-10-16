@Docyt.module "SignUpApp.CreditCardInfo", (CreditCardInfo, App, Backbone, Marionette, $, _) ->

  class CreditCardInfo.Router extends Marionette.AppRouter
    appRoutes:
      'sign_up/credit': 'showCreditCardInfo'
