@Docyt.module "Common.BaseDocuments.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Marionette.Object

    fetchDocument: (documentId, client) ->
      document = @getDocument(documentId)
      document.fetch().done =>
        documentShowLayoutView = @getDocumentShowLayoutView()
        Docyt.mainRegion.show(documentShowLayoutView)

        documentRightSideMenuView = @getDocumentRightSideMenuView()
        documentShowLayoutView.rightSideRegion.show(documentRightSideMenuView)

        documentView = @getDocumentView(document)
        documentShowLayoutView.detailsRegion.show(documentView)

        sideMenuView = @getSideMenuView(client)
        documentShowLayoutView.sideMenuRegion.show(sideMenuView)

        documentFields = @getDocumentFields()
        documentFields.fetch(url: "/api/web/v1/documents/#{documentId}/document_fields").done =>
          documentFieldsView = @getDocumentFieldsView(documentFields, documentId)
          documentRightSideMenuView.documentFieldsRegion.show(documentFieldsView)

          documentOwnersCollection = @getDocumentOwners(document.get('document_owners'))
          documentOwnersView = @getDocumentOwnersView(documentOwnersCollection)
          documentRightSideMenuView.documentOwnersRegion.show(documentOwnersView)

    getDocument: (documentId) ->
      new Docyt.Entities.Document
        id: documentId

    getDocumentShowLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.Layout

    getDocumentOwners: (collection) ->
      new Docyt.Entities.DocumentOwners(collection)

    getDocumentFields: ->
      new Docyt.Entities.DocumentFields

    getDocumentView: (document) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentView
        model: document

    getDocumentRightSideMenuView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.RightSideMenuLayout

    getSideMenuView: (client) =>
      new Docyt.AdvisorHomeApp.Clients.Show.SideMenu
        model: client
        activeSubmenu: 'documents'

    getDocumentFieldsView: (documentFields, documentId) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.Index.DocumentFieldsList
        collection: documentFields
        documentId: documentId

    getDocumentOwnersView: (documentOwners) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentOwners.Index.DocumentOwnersList
        collection: documentOwners
