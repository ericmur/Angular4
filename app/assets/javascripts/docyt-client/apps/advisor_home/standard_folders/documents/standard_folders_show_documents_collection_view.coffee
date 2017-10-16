@Docyt.module "AdvisorHomeApp.StandardFolders.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentsList extends Marionette.CollectionView
    className: 'documents-list-wrap'

    getChildView: ->
      Index.DocumentView

    childViewOptions: ->
      business: @options.business

    initialize: ->
      Docyt.vent.on('file:upload:success', @addUploadedDocument)
      Docyt.vent.on('uploaded:document:remove:from:uncategorized', @removeUncategorizedDocumentFromPage)
      @business       = @options.business
      @standardFolder = @options.standardFolder

    onRender: ->
      @removeDragAndDropEventListeners()
      @setupDragAndDrop()

    onDestroy: ->
      Docyt.vent.off('file:upload:success', @addUploadedDocument)
      Docyt.vent.on('uploaded:document:remove:from:uncategorized')
      @removeDragAndDropEventListeners()

    removeDragAndDropEventListeners: ->
      return unless @mainPane

      @htmlBody.off('dragleave dragend')
      @htmlBody.off('dragenter dragover')
      @htmlBody.off('drop')

    setupDragAndDrop: ->
      @htmlBody = $('body')
      @mainPane = $('.main-container')

      @htmlBody.on('dragleave dragend',  @highlightDropzone)
      @htmlBody.on('dragenter dragover', @highlightDropzone)
      @htmlBody.on('drop', @drop)

    isInsideOfBounds: (event) ->
      pointX = event.originalEvent.pageX
      pointY = event.originalEvent.pageY

      pointX > 0 || pointY > 0

    highlightDropzone: (e) =>
      e.preventDefault()
      @mainPane.toggleClass('drop__zone_active', @isInsideOfBounds(e))

    drop: (e) =>
      e.preventDefault()
      e.originalEvent.dataTransfer.dropEffect = 'copy'
      @mainPane.toggleClass('drop__zone_active', false)

      modalView = new Docyt.AdvisorHomeApp.Shared.DocumentsUploadModalView
        files:    new Docyt.Services.DragAndDropFileUploadHelper(e).getFilesFromEvent()
        business: @business

      Docyt.modalRegion.show(modalView)

    addUploadedDocument: (uploadedDocument) =>
      documentModel = new Docyt.Entities.Document(uploadedDocument.documentJson)
      documentModel.set('isNewDocument', true)
      @collection.add(documentModel) unless @standardFolder

    removeUncategorizedDocumentFromPage: (documents) =>
      for document in documents
        standardDocument = document.get('standard_document')
        @addDocumentToCategory(document, standardDocument)

    addDocumentToCategory: (document, standardDocument) ->
      if @standardFolder && standardDocument.standard_folder_id == @standardFolder.get('id')
        @collection.add(document)
      else
        Docyt.vent.trigger('category:changed', @getChangedCategoryId(standardDocument))

        @collection.remove(document) if document.get('sendToBox')

    getChangedCategoryId: (standardDocument) ->
      if standardDocument.category_name == null && standardDocument.standard_folder_id == null && standardDocument.name != null
        parseInt(configData.miscCategory)
      else
        standardDocument.standard_folder_id
