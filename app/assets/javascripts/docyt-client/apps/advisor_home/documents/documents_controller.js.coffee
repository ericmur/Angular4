@Docyt.module "AdvisorHomeApp.Documents", (Documents, App, Backbone, Marionette, $, _) ->

  class Documents.Controller extends Marionette.Object

    showDocument: (documentId) ->
      document = @getDocument(documentId)
      document.fetch().done =>
        documentShowLayoutView = @getDocumentShowLayoutView()

        App.mainRegion.show(documentShowLayoutView)

        documentView = @getDocumentView(document)
        documentShowLayoutView.detailsRegion.show(documentView)

        if document.has('standard_document_id') && document.get('document_owners').length
          documentRightSideMenuView = @getDocumentRightSideMenuView()
          documentShowLayoutView.rightSideRegion.show(documentRightSideMenuView)

          documentFields = @getDocumentFields()
          documentFields.fetch(
            url: "/api/web/v1/documents/#{documentId}/document_fields"
          ).done =>
            documentFieldsView = @getDocumentFieldsView(documentId, documentFields)
            documentRightSideMenuView.documentFieldsRegion.show(documentFieldsView)

            documentOwnersCollection = @getDocumentOwners(document.get('document_owners'))
            documentOwnersView = @getDocumentOwnersView(documentOwnersCollection)
            documentRightSideMenuView.documentOwnersRegion.show(documentOwnersView)

    getDocumentShowLayoutView: ->
      new Docyt.AdvisorHomeApp.Documents.Layout

    getDocument: (documentId) ->
      new Docyt.Entities.Document
        id: documentId

    getDocumentOwners: (collection) ->
      new Docyt.Entities.DocumentOwners(collection)

    getDocumentFields: ->
      new Docyt.Entities.DocumentFields

    getDocumentView: (document) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentView
        model: document

    getDocumentRightSideMenuView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.RightSideMenuLayout

    getDocumentFieldsView: (documentId, documentFields) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.Index.DocumentFieldsList
        collection: documentFields
        documentId: documentId

    getDocumentOwnersView: (documentOwners) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentOwners.Index.DocumentOwnersList
        collection: documentOwners
