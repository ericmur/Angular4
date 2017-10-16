@Docyt.module "AdvisorHomeApp.Clients.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'clients/': 'showClients'
      'clients': 'showClients'
      'clients/:biz_id': 'showClients'
