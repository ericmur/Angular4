@Docyt.module "SignUpApp.BusinessInfo", (BusinessInfo, App, Backbone, Marionette, $, _) ->

  class BusinessInfo.Router extends Marionette.AppRouter
    appRoutes:
      'sign_up/business': 'showBusinessInfo'
