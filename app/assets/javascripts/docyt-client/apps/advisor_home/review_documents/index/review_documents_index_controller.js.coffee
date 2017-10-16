@Docyt.module "AdvisorHomeApp.ReviewDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Marionette.Object

    initialize: ->
      Docyt.vent.on('clients:review_documents:modal:show', @showAssignToClientModal)
      Docyt.vent.on('clients:review_documents:email:modal:show', @showEmailContentModal)

    onDestroy: ->
      Docyt.vent.off('clients:review_documents:modal:show')
      Docyt.vent.off('clients:review_documents:email:modal:show')

    documentsForReviewIndex: ->
      @documentsForReviewLayout = @getDocumentsForReviewLayoutView()
      App.mainRegion.show(@documentsForReviewLayout)

      documentsForReviewHeaderMenu = @getDocumentsForReviewHeaderMenu(@documentsForReviewLayout)
      @documentsForReviewLayout.headerMenuRegion.show(documentsForReviewHeaderMenu)

      attachments = @getDocuments()
      attachments.fetch(url: "/api/web/v1/advisor/documents/documents_via_email").done =>
        documentsForReviewList = @getDocumentsForReviewListView(attachments, @documentsForReviewLayout)
        @documentsForReviewLayout.documentsListRegion.show(documentsForReviewList)

    getDocuments: ->
      new Docyt.Entities.Documents()

    getDocumentsForReviewLayoutView: ->
      new Index.Layout()

    getDocumentsForReviewHeaderMenu: (layout) ->
      new Index.HeaderMenu({ layout: layout })

    getDocumentsForReviewListView: (attachments) ->
      new Index.DocumentsListView({ collection: attachments })

    getAssignToClientModalView: (clients, documents) ->
      new Index.AssignClientModal({ collection: clients, documents: documents })

    getEmailContentModal: (document) ->
      new Index.EmailContentModal({ model: document })

    getClients: ->
      clientsCollection = new App.Entities.Clients()

    showAssignToClientModal: (documents) =>
      clientsCollection   = @getClients()
      clientsCollection.fetch().done () =>
        assignToClientModalView = @getAssignToClientModalView(clientsCollection, documents)
        @documentsForReviewLayout.documentsModalRegion.show(assignToClientModalView)

    showEmailContentModal: (document) =>
        emailContentModal = @getEmailContentModal(document)
        @documentsForReviewLayout.documentsModalRegion.show(emailContentModal)
