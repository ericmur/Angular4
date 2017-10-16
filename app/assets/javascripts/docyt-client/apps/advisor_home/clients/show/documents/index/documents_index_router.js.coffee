@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'clients/:id/details/documents': 'showClientDetailsDocuments'
      'clients/:id/details/documents/contacts/:contact_id/:contact_type': 'showClientDetailsDocumentsContacts'
