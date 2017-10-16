@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentsList extends Marionette.CompositeView
    template: 'advisor_home/clients/show/documents/index/clients_documents_list_tmpl'

    ui:
      documentSeparator: '.hor-separator'

    getChildView: ->
      if @options.structureType == 'flat'
        Index.ContactDocumentItemView
      else
        Index.DocumentItemView

    childViewOptions: ->
      client:  @options.client
      contact: @options.contact
      isIndexPage: @options.isIndexPage
      parentCollectionView: @

    attachBuffer: (collectionView, buffer) ->
      collectionView.$el.find('.client__docs-list').append(buffer)

    # override for default collectionView method, needed to correctly add uploaded documents
    attachHtml: (collectionView, childView, index) ->
      if collectionView.isBuffering
        collectionView._bufferedChildren.splice index, 0, childView
      else
        if !collectionView._insertBefore(childView, index)
          collectionView.$el.find('.client__docs-list').append(childView.$el)

    templateHelpers: ->
      client: @options.client

    initialize: ->
      @listenTo(@collection, 'add remove', @toggleSeparator) if @options.isIndexPage
      Docyt.vent.on('file:upload:success', @addUploadedDocument)
      Docyt.vent.on('file:destroy:success', @removeDocument)
      Docyt.vent.on('uploaded:document:update:category', @updateDocumentCategory)
      Docyt.vent.on('uploaded:document:remove:from:uncategorized', @removeUncategorizedDocumentFromPage)

    onRenderCollection: ->
      @setCategoriesOptionsForDocuments()

    addUploadedDocument: (uploadedDocWithClientId) =>
      documentModel = new Docyt.Entities.Document(uploadedDocWithClientId.documentJson)
      documentModel.set('isNewDocument', true)
      @collection.add(documentModel) unless @options.standardFolder

    removeDocument: (documentModel) =>
      @collection.remove(documentModel)

    onShow: ->
      @setupDragAndDrop()
      if @options.isIndexPage then @toggleSeparator() else @ui.documentSeparator.hide()

    toggleSeparator: ->
      if @collection.models.length == 0 then @ui.documentSeparator.hide() else @ui.documentSeparator.show()

    onDestroy: ->
      @removeDragAndDropEventListeners()
      Docyt.vent.off('file:upload:success')
      Docyt.vent.off('file:destroy:success')
      Docyt.vent.off('uploaded:document:update:category')
      Docyt.vent.off('uploaded:document:remove:from:uncategorized')

    removeDragAndDropEventListeners: ->
      @htmlBody.off('dragleave dragend')
      @htmlBody.off('dragenter dragover')
      @htmlBody.off('drop')

    setupDragAndDrop: ->
      # Optimization: save DOM elements to reuse them instead of searching for them each time
      @mainDropPane = $('#client-main-pane, #contact-main-pane')
      @htmlBody = $('body')

      # events to listen to for drag'n'drop
      @htmlBody.on('dragleave dragend', @hideClientDropzone)
      @htmlBody.on('dragenter dragover', @highlightClientDropzone)
      @htmlBody.on('drop', @drop)

    highlightClientDropzone: (e) =>
      e.preventDefault()

      @mainDropPane.toggleClass('drop__zone_active', @isInsideOfBounds(e))

    hideClientDropzone: (e) =>
      e.preventDefault()

      @mainDropPane.toggleClass('drop__zone_active', @isInsideOfBounds(e))

    isInsideOfBounds: (event) ->
      pointX = event.originalEvent.pageX
      pointY = event.originalEvent.pageY

      pointX > 0 || pointY > 0

    drop: (e) =>
      e.preventDefault()
      e.originalEvent.dataTransfer.dropEffect = 'copy'
      files = new Docyt.Services.DragAndDropFileUploadHelper(e).getFilesFromEvent({documentPage: true})

      @showDocumentsUploadModal(files) if files.length

      @mainDropPane.toggleClass('drop__zone_active', false)

    setCategoriesOptionsForDocuments: ->
      @categories = new Docyt.Entities.StandardDocuments

      @categories.fetch(data: @setParams()).done =>
        Docyt.vent.trigger('categories:loaded', @categories)

    removeUncategorizedDocumentFromPage: (documents) =>
      for doc in documents
        standardDocument = doc.get('standard_document')
        if standardDocument.category_name == null && standardDocument.standard_folder_id == null && standardDocument.name != null
          Docyt.vent.trigger('category:changed', parseInt(configData.miscCategory))
        else
          Docyt.vent.trigger('category:changed', doc.get('standard_document').standard_folder_id)

        @addDocument(doc, standardDocument)

    updateDocumentCategory: (documents) =>
      for doc in documents
        @collection.get(doc.get('id')).set(doc.attributes)

    showDocumentsUploadModal: (files) ->
      modalView = new Docyt.AdvisorHomeApp.Shared.DocumentsUploadModalView
        files:   files
        client:  @options.client
        contact: @options.contact
        parentCollectionView: @

      Docyt.modalRegion.show(modalView)

    setParams: ->
      data =
        client_id:   @options.client.get('id')
        client_type: @options.client.get('type')

      data

    addDocument: (document, standardDocument) ->
      if @options.standardFolder && standardDocument.standard_folder_id == @options.standardFolder.get('id')
        @collection.add(document)
      else
        @collection.remove(document) if document.get('sendToBox')
