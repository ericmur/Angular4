@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.ChatMessageUploadDocumentItemView extends Marionette.CompositeView
    className: 'client__mes-card-wrap'
    tagName:   'div'
    template:  'advisor_home/clients/show/messages/clients_messages_upload_item_tmpl'

    DELAY = 5000

    ui:
      deleteFile:    '.delete-file'
      progressBar:   '.file-status-line'
      messageItem:   '.message-item'
      markAsUnread:  '.mark-unread-message'
      fileTypeIcon:  '.file-icon'
      cancelUpload:  '.cancel-upload'
      deleteMessage: '.delete-message'
      firstPageIconImg: '.first-page-icon'

      linktoShowDocument:  '.show-document-js'
      messageImageWrapper: '.message-file-upload-image'

      messageContextMenu:   '.message-context-menu'
      messageTriangleItem:  '.message-triangle-item'

      documentContextMenu:  '.document-context-menu'
      documentTriangleItem: '.document-triangle-item'

      progressUploadValue: '.progress-upload'
      progressDownloadValue: '.message-document-download-progress-info'

      documentInfo: '.message-file-document-info'
      downloadProgressBar: '.message-document-download-progress'
      messageTextContent: '.client__mes-content-text'

      saveDocumentToClient:  '.save-to-client-documents-js'
      saveDocumentToAdvisor: '.save-to-advisor-documents-js'

    events:
      'click @ui.deleteFile':    'deleteMessage'
      'click @ui.cancelUpload':  'cancelUpload'
      'click @ui.markAsUnread':  'markAsUnread'
      'click @ui.deleteMessage': 'deleteMessage'

      'click @ui.linktoShowDocument':    'checkDocument'
      'click @ui.saveDocumentToClient':  'categorizeAndSaveToClient'
      'click @ui.saveDocumentToAdvisor': 'categorizeAndSaveToAdvisor'

      'click @ui.messageTriangleItem':     'showMessageMenuBar'
      'mouseleave @ui.messageContextMenu': 'hideMessageMenuBar'

      'click @ui.documentTriangleItem':     'showDocumentMenuBar'
      'mouseleave @ui.documentContextMenu': 'hideDocumentMenuBar'

    templateHelpers: ->
      fileInfo:  @file.getFileInfo()
      fileSize:  filesize(@file.get('storage_size'))
      fileName:  @file.getFileName()

      avatarUrl:    @model.getSenderAvatarUrl()
      timestamp:    moment(@model.get('created_at')).format("ddd, MMM D YYYY, h:mm A")
      clientName:   @model.get('sender_name')
      previewImage: @hasPreviewImage()

      hasAccessDocument:   @hasAccessDocument()
      fileWithoutCategory: !@isCategorizedDocument()

    initialize: ->
      Docyt.vent.on('url:created', @setUrl)
      Docyt.vent.on('file:upload:started',   @checkUploadProgress)
      Docyt.vent.on('file:upload:progress',  @updateProgress)
      Docyt.vent.on('file:download:success', @showFirstPageIcon)
      Docyt.vent.on('message:item:download:progress:bar', @downloadProgress)
      Docyt.vent.on('uploaded:document:remove:from:uncategorized', @updateDocumentMessage)
      @file = @getDocumentModel()

    onDestroy: =>
      Docyt.vent.off('url:created')
      Docyt.vent.off('file:upload:started')
      Docyt.vent.off('file:upload:progress')
      Docyt.vent.off('file:download:success')
      Docyt.vent.off('message:item:download:progress:bar')
      Docyt.vent.off('uploaded:document:remove:from:uncategorized')
      @clickEventListener.off('click') if @clickEventListener
      clearTimeout(@delayed) if @delayed

    onRender: ->
      @setFileIcon()
      @checkStandardDocument()
      @hideDocumentTriangleItem()
      @fetchDocumentInfo()

    checkUploadProgress: (data, document) =>
      if @file.get('original_file_name') == data.name && @file.get('id') == document.id

        window.onbeforeunload = ->
          "This page is asking you to confirm that you want to leave - data you have entered may not be saved"

        @clickEventListener = $('a').on 'click', (evt) =>
          href = evt.currentTarget.getAttribute('href')
          @stopEvent(evt)
          Docyt.vent.trigger('warning:modal:when:uploading', href)

    cancelUpload: ->
      @destroy()
      window.onbeforeunload = null
      Docyt.vent.trigger('cancel:uploading:to:s3')
      Docyt.vent.trigger('cancel:upload:document', @model.get('chat_document'))

    updateProgress: (progress) =>
      if progress.filename == @file.get('original_file_name')
        percentage = progress.progressPercentage

        Docyt.vent.trigger('progress:bar:header', percentage, @file.get('storage_size'))

        @ui.progressBar.width("#{percentage}%")
        @ui.progressUploadValue.text("#{percentage}% of #{filesize(@file.get('storage_size'))}")

        if percentage == 100
          window.onbeforeunload = null
          @model.set('uploading', false)
          @render()

    setFileIcon: ->
      if @isCategorizedDocument()
        @ui.fileTypeIcon.addClass('icon-empty-file') if @fileIsConverting() || @haveNoPages()
      else
        @ui.fileTypeIcon.addClass(@file.getIconType())

    getDocumentModel: ->
      new Docyt.Entities.Document(@model.get('chat_document')) if @model.has('chat_document')

    showMessageMenuBar: ->
      if @ui.messageContextMenu.is(':hidden')
        @ui.messageContextMenu.show()
      else
        @ui.messageContextMenu.hide()

    showDocumentMenuBar: ->
      if @ui.documentContextMenu.is(':hidden')
        @ui.documentContextMenu.show()
      else
        @ui.documentContextMenu.hide()

    hideMessageMenuBar: ->
      @ui.messageContextMenu.hide() if @ui.messageContextMenu.is(':visible')

    hideDocumentMenuBar: ->
      @ui.documentContextMenu.hide() if @ui.documentContextMenu.is(':visible')

    deleteMessage: (e) ->
      e.stopPropagation()

      modalView = new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.СonfirmationModal

      Docyt.modalRegion.show(modalView)

      modalView.on('confirm', =>
        @model.destroy()
        Docyt.vent.trigger('update:documents:count:header', event: 'deleteDocument')
        modalView.destroy()
      )

    hasPreviewImage: ->
      if @isCategorizedDocument() && @file.has('first_page_s3_key') && @file.get('have_access')

        downloadService = new Docyt.Services.DownloadFromS3(
          s3_key: @file.get('first_page_s3_key')
          symmetric_key: @file.get('symmetric_key')
        )
        downloadService.download()
        true

    showFirstPageIcon: (unit8array, s3Key) =>
      if @file.get('first_page_s3_key') == s3Key
        imgBase64 = 'data:image/jpeg;base64,' + btoa(String.fromCharCode.apply(null, unit8array))
        @ui.firstPageIconImg.attr('src', imgBase64)

    hasAccessDocument: =>
      if @isCategorizedDocument()
        @file.get('have_access')
      else
        true

    checkStandardDocument: =>
      if @isCategorizedDocument() && !@file.get('have_access')
        @ui.messageImageWrapper.css('cursor', 'default')

    markAsUnread: ->
      @ui.messageContextMenu.hide()
      @model.markAsUnread()

    categorizeAndSaveToClient: ->
      return unless @options.client

      @saveDocumentToOwner(@options.client)

    categorizeAndSaveToAdvisor: ->
      Docyt.currentAdvisor.set(
        type: 'User'
        parsed_fullname: Docyt.currentAdvisor.get('full_name')
      )

      @saveDocumentToOwner(Docyt.currentAdvisor)

    saveDocumentToOwner: (owner) ->
      file = @setParamsToFile(owner)

      documents = new Docyt.Entities.Documents(file)

      modalView = @getFileCategorizationModal(owner, documents)

      Docyt.modalRegion.show(modalView)

    updateDocumentMessage: (documents) =>
      if @file.get('id') == documents[0].get('id')
        @file.set(documents[0].attributes)
        @render()

    hideDocumentTriangleItem: ->
      if @model.get('sender_id') != Docyt.currentAdvisor.get('id') && (@isCategorizedDocument() && @isPdf())
        @ui.documentTriangleItem.hide()

    isCategorizedDocument: ->
      @file.has('standard_document_id')

    isPdf: ->
      @file.get('file_content_type') == 'application/pdf'

    getFileCategorizationModal: (owner, documents) ->
      new Docyt.AdvisorHomeApp.Shared.FilesCategorizationProgressModal
        client:     owner
        collection: documents

    setParamsToFile: (owner) ->
      @file.set(
        temporary: true
        document_owners: [
          owner_id:   owner.get('id')
          owner_type: owner.get('type') || 'User'
        ]
      )

    downloadUnsupportedFile: ->
      downloadService = new Docyt.Services.DownloadFromS3(
        s3_key: @file.get('final_file_key')
        symmetric_key: @file.get('symmetric_key')
        trigger_name: 'url:created'
      )

      downloadService.download()

    downloadProgress: (progress) =>
      if @file.get('final_file_key') == progress.s3Key
        percentage = progress.percentage

        @showDownloadProgressBar() if @ui.downloadProgressBar.is(':hidden')

        @ui.progressBar.width("#{percentage}%")
        @ui.progressDownloadValue.text("#{percentage}% of #{filesize(@file.get('storage_size'))}")

    showDownloadProgressBar: =>
      @ui.documentInfo.hide()
      @ui.downloadProgressBar.show()

    stopEvent: (event) ->
      event.stopPropagation()
      event.preventDefault()

    fetchDocumentInfo: ->
      if @fileIsConverting()
        @file.fetch().success (response) =>
          if response.document.state == 'converted'
            @file.set(response.document)
            @render()
        .error =>
          toastr.error('The server is currently unavailable. Try again later.', 'Something went wrong!')
        .done =>
          @delayed = setTimeout (=> @fetchDocumentInfo()), DELAY

    fileIsConverting: ->
      @file.get('state') == 'converting'

    haveNoPages: ->
      @file.get('pages_count') == 0

    hasDocumentFields: ->
      @file.get('document_fields_count') > 0

    setUrl: (data, s3Key) =>
      if @file.get('final_file_key') == s3Key
        @ui.messageTextContent.text('Shared document:')
        file = new Blob([ data ], type: @file.get('file_content_type'))
        url = (window.URL || window.webkitURL).createObjectURL(file)

        @ui.linktoShowDocument.attr('href': url, 'download': @file.get('original_file_name'))
        @ui.documentInfo.show()
        @ui.downloadProgressBar.hide()

        link = document.createElement("a")
        link.download = @file.get('original_file_name')
        link.href = url

        $('body').append(link)
        $(link)[0].click()
        $(link)[0].remove()

    checkDocument: ->
      return @checkCategorizedDocument() if @isCategorizedDocument()

      @checkUncategorizedDocument()

    checkCategorizedDocument: ->
      return @showChatDocument() if !@fileIsConverting() || @isPdf()

      if @hasDocumentFields() && (@haveNoPages() || !@file.get('final_file_key'))
        @showChatDocument()
      else
        @startDownloadFile() if !@ui.linktoShowDocument.attr('href')

    checkUncategorizedDocument: ->
      return @showChatDocument() if @isPdf()

      @startDownloadFile() if !@ui.linktoShowDocument.attr('href')

    startDownloadFile: ->
      @showDownloadProgressBar()

      @ui.linktoShowDocument.attr('download': @file.get('original_file_name'))
      @ui.messageTextContent.text('Downloading document:')
      @downloadUnsupportedFile()

    showChatDocument: ->
      Docyt.vent.trigger('show:chat:document', @model.get('id'), @file.get('id'))
