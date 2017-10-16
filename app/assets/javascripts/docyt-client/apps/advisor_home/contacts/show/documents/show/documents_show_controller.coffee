@Docyt.module "AdvisorHomeApp.Contacts.Show.Documents.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Docyt.Common.BaseDocuments.Show.Controller

    showDocument: (contactId, documentId) ->
      contact = @getContact(contactId)
      contact.fetch().done =>
        @fetchDocument(documentId, contact)

    getContact: (contactId) ->
      new App.Entities.Contact
        id: contactId
