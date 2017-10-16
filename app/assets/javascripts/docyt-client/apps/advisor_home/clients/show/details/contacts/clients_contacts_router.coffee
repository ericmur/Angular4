@Docyt.module "AdvisorHomeApp.Clients.Show.Details.Contacts.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'clients/:id/details/contacts/:name': 'showClientContacts'
