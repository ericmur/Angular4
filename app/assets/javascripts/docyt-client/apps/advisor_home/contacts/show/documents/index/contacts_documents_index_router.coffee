@Docyt.module "AdvisorHomeApp.Contacts.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'contacts/:id/details/documents': 'showContactDetailsDocuments'
      'contacts/:id/details/documents/contacts/:contact_id/:contact_type': 'showContactDetailsDocumentsContacts'
