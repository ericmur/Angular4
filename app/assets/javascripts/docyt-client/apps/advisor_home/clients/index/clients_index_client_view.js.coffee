@Docyt.module "AdvisorHomeApp.Clients.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ClientView extends Marionette.ItemView
    template:  'advisor_home/clients/index/client_view_tmpl'

    ui:
      clientWrapper: '.clients__client'
      clientName:    '.clients__client-name-text'
      messagesLink:  '#messages-link'
      documentsLink: '#documents-link'
      workflowsLink: '#workflows-link'

    events:
      'drop @ui.clientWrapper': 'uploadFilesForClient'

    templateHelpers: ->
      avatarUrl: @getClientAvatarUrl()

    initialize: ->
      @listenTo(@model, 'change', @render)
      Docyt.vent.on('file:upload:success', @addUploadedDocument)
      Docyt.vent.on('clients:list:highlight', @highlightDropZone)
      Docyt.vent.on('update:messages:count', @updateMessagesCount)
      Docyt.vent.on('clients:list:highlight:remove', @hideClientDropzone)

    onDestroy: ->
      Docyt.vent.off('file:upload:success')
      Docyt.vent.off('update:messages:count')
      Docyt.vent.off('clients:list:highlight')
      Docyt.vent.off('clients:list:highlight:remove')

    onRender: ->
      @disableEmptyLinks()
      @greyOutName() unless @model.get('consumer_id')

    addUploadedDocument: (uploadedDocWithClientId) =>
      if @model.get('id') == uploadedDocWithClientId.clientId
        currentDocumentsCount = @model.get('documents_count')
        @model.set('documents_count', currentDocumentsCount+1)

    highlightDropZone: =>
      @ui.clientWrapper.addClass('drop__zone_active')

    hideClientDropzone: =>
      @ui.clientWrapper.removeClass('drop__zone_active')

    uploadFilesForClient: (e) ->
      e.preventDefault()
      e.stopPropagation()
      Docyt.vent.trigger('clients:list:highlight:remove', @hideClientDropzone)
      e.originalEvent.dataTransfer.dropEffect = 'copy'
      files = new Docyt.Services.DragAndDropFileUploadHelper(e).getFilesFromEvent()
      modalView = new Docyt.AdvisorHomeApp.Shared.DocumentsUploadModalView
        files: files
        client: @model

      Docyt.modalRegion.show(modalView)

    greyOutName: ->
      @ui.clientName.addClass('in-grey-500')

    disableEmptyLinks: ->
      @disableEmptyMessages()  if @model.get('unread_messages_count') == 0
      @disableEmptyWorkflows() if @model.get('workflows_count') == 0
      @disableEmptyDocuments() if @model.get('documents_count') == 0

    disableEmptyMessages: ->
      @ui.messagesLink.addClass('disabled')

    disableEmptyWorkflows: ->
      @ui.workflowsLink.addClass('disabled')

    disableEmptyDocuments: ->
      @ui.documentsLink.addClass('disabled')

    getClientAvatarUrl: ->
      if @model.has('avatar')
        s3_object_key = @model.get('avatar').s3_object_key
        "https://#{configData.bucketName}.s3.amazonaws.com/#{s3_object_key}"

    updateMessagesCount: (data) =>
      if @model.get('chat_id') == data['chat_id']
        @model.set('unread_messages_count', @model.get('unread_messages_count') + 1)
