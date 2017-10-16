@Docyt.module "AdvisorHomeApp.ReviewDocuments.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Marionette.Object

    showDocument: (documentId) ->
      reviewDocument = @getDocument(documentId)
      reviewDocument.fetchForAdvisorViaEmail().done =>
        documentView = @getDocumentView(reviewDocument)
        App.mainRegion.show(documentView)

    getDocument: (documentId) ->
      new Docyt.Entities.Document
        id: documentId

    getDocumentView: (document) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentView
        model: document
