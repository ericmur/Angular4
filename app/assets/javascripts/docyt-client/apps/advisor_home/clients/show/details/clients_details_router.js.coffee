@Docyt.module "AdvisorHomeApp.Clients.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'clients/:id/details': 'showClientDetails'
