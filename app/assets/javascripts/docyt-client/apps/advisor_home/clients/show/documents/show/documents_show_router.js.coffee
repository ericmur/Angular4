@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'clients/:client_id/documents/:id': 'showDocument'
