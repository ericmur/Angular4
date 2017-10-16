@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.GroupsList extends Marionette.CompositeView
    childViewContainer: '.groups-messages-list'
    template: 'advisor_home/clients/show/messages/clients_messages_groups_list_tmpl'

    ui:
      noMoreMessagesLabel:    '.no-more-messages-label-js'
      loadOlderMessagesLink: '.load-older-messages-js'

    events:
      'click @ui.loadOlderMessagesLink': 'getPreviousMessages'

    getChildView: ->
      Messages.MessagesList

    childViewOptions: ->
      dates:      @collection
      collection: @options.messages

    initialize: ->
      Docyt.vent.on('chat:update', @chatUpdate)
      Docyt.vent.on('show:chat:document', @showChatDocument)
      Docyt.vent.on('file:upload:success', @documentSaved)
      Docyt.vent.on('upload:file:from:action:bar', @uploadFiles)
      Docyt.vent.on('show:found:messages', @showFoundMessages)
      Docyt.vent.on('cancel:upload:document', @addCancelUploadMessage)
      Docyt.vent.on('set:document:id:messages:page', @uploadDocumentMessage)
      @options.messages.subscribeToChat(@options.chatId)

    onRender: ->
      @removeDragAndDropEventListeners()
      @setLayoutStyleForMessages()
      @setOlderMessagesLink()
      @setupDragAndDrop()

    # custom scrollbar need to be used only in onShow, it won't work in onRender
    onShow: ->
      @initCustomScrollbar()
      @scrollToBottom()

    onDestroy: ->
      Docyt.vent.off('set:document:id:messages:page')
      Docyt.vent.off('upload:file:from:action:bar')
      Docyt.vent.off('cancel:upload:document')
      Docyt.vent.off('file:upload:success')
      Docyt.vent.off('show:found:messages')
      Docyt.vent.off('show:chat:document')
      Docyt.vent.off('chat:update')
      @options.messages.unsubscribeFromChat()
      @removeDragAndDropEventListeners()
      @clearLayoutStyleForMessages()

    setupDragAndDrop: ->
      @mainDropPane = $('#workflow-main-pane, #client-main-pane, #messaging-main-pane, #contact-main-pane')
      @htmlBody = $('body')

      @htmlBody.on('dragleave dragend', @hideClientDropzone)
      @htmlBody.on('dragenter dragover', @highlightClientDropzone)
      @htmlBody.on('drop', @drop)

    chatUpdate: (newMessage) =>
      message = newMessage.get('message')

      if message && message.action == 'update'
        @updateExistingMessage(message)
        @render()
      else if message && message.action == 'delete'
        @removeMessage(message)
        @render()
      else
        @checkDocumentId(newMessage)

    checkDocumentId: (newMessage) ->
      if newMessage.has('document_id')
        messages = _.filter(@options.messages.models, (message) ->
          if message.has('chat_document') && message.get('chat_document').id == newMessage.get('document_id')
            message.get('chat_document')
        )
        @checkFromMessage(messages, newMessage)
      else
        @addNewMessage(newMessage)

    checkFromMessage: (messages, newMessage) ->
      if messages.length > 0
        @setMessageId(messages, newMessage)
        @render()
      else
        @getDocumentInfo(newMessage)

    getDocumentInfo: (newMessage) =>
      Docyt.vent.trigger('show:spinner')
      document = new Docyt.Entities.Document(id: newMessage.get('document_id'))
      document.fetch().success (response) =>
        newMessage.set('chat_document', response.document)
        @addNewMessage(newMessage)
        Docyt.vent.trigger('hide:spinner')
      .error =>
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Unable to load the document. Try later.', 'Something went wrong!')

    setMessageId: (messages, newMessage) ->
      _.each(messages, (message) ->
        file = message.get('chat_document')
        if file.id == newMessage.get('document_id')
          message.set('id', newMessage.get('message_id'))
        )

    updateExistingMessage: (message) =>
      existingMessage = @options.messages.get(message.message_id)
      existingMessage.set('text', message.text)

    removeMessage: (message) =>
      @options.chatInfo.chat_messages_count -= 1
      @options.messages.remove(message.message_id)

    addNewMessage: (newMessage) =>
      if @options.collection.length > 0
        @options.messages.push(newMessage)
      else
        date = new Backbone.Model({date: moment(newMessage.get('created_at')).format('MMMM YYYY')})
        @options.collection.push(date)
        @options.messages.push(newMessage)
      @options.chatInfo.chat_messages_count += 1

    removeDragAndDropEventListeners: ->
      return unless @htmlBody

      @htmlBody.off('dragleave dragend')
      @htmlBody.off('dragenter dragover')
      @htmlBody.off('drop')

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

      files = new Docyt.Services.DragAndDropFileUploadHelper(e).getFilesFromEvent()

      @uploadFiles(files) if files.length > 0

      @mainDropPane.toggleClass('drop__zone_active', false)

    uploadFiles: (files) =>
      @filesCollection = @getFilesCollection(files)
      uploader = @uploadToS3Service(files)

      for file in @filesCollection.models
        uploader.uploadSingleFile(file)

    addCancelUploadMessage: (file) =>
      message = new Docyt.Entities.Message
        text:        "Canceled upload of #{file.original_file_name}"
        sender_name: Docyt.currentAdvisor.getName()

      @options.messages.push(message)

    documentSaved: (documentHash) =>
      document = documentHash.documentJson

      file = _.find(@filesCollection.models, (file) ->
        file.get('original_file_name') == document.original_file_name
      )

      if file
        params =
          type:        'web'
          document_id: document.id

        message = _.find(@options.messages.models, (message) ->
          message.has('chat_document') && message.get('chat_document').id == document.id
        )

        message.attributes.chat_document.final_file_key = document.final_file_key

        Docyt.vent.trigger('update:documents:count:header', event: 'addDocument')

        Docyt.fayeClient.publish("/chats/#{@options.chatId}", params)

    uploadDocumentMessage: (data) =>
      message = new Docyt.Entities.Message
        chat_id:       @options.chatId
        sender_id:     Docyt.currentAdvisor.get('id')
        uploading:     true
        sender_name:   Docyt.currentAdvisor.getName()
        sender_avatar: Docyt.currentAdvisor.get('avatar')
        chat_document: data.file

      @chatUpdate(message)

    uploadToS3Service: (files) =>
      data =
        files:       files
        temporary:   true
        chatMembers: @getChatMembers()

      new Docyt.Services.UploadToS3Service(data)

    getFilesCollection: (files) ->
      new Docyt.Services.FilesCollectionBuilder(files).populate()

    onAddChild: ->
      $('.messages-region').mCustomScrollbar("scrollTo", 'last', { timeout: 100 })

    scrollToBottom: ->
      $('.messages-region').mCustomScrollbar("scrollTo", 'last', { timeout: 100 })

    setLayoutStyleForMessages: ->
      $('body').addClass('two-column')

    clearLayoutStyleForMessages: ->
      $('body').removeClass('two-column')

    initCustomScrollbar: ->
      $('.messages-region').mCustomScrollbar(theme: 'minimal-dark', scrollInertia: 100)

    getPreviousMessages: (e) ->
      e.preventDefault()

      if @isAllMessages()
        @ui.loadOlderMessagesLink.toggleClass('hidden')
      else
        Docyt.vent.trigger('show:spinner')
        @loadOlderMessages()

    loadOlderMessages: ->
      chatId        = @options.chatId
      messages      = new Docyt.Entities.Messages()
      fromMessageId = @options.messages.first().get('id')

      messages.fetch(
        url: "/api/web/v1/messages"
        data: { chat_id: chatId, from_message_id: fromMessageId }
      ).success (response) =>
        @appendPreviousMessages(response.messages)
        @setOlderMessagesLink()

    appendPreviousMessages: (messages) ->
      _.each(messages, (message) =>
        message.fromThePast = true
        @options.messages.unshift(message)
      )
      Docyt.vent.trigger('hide:spinner')

    showFoundMessages: =>
      @options.chatInfo = @options.messages.chatInfo
      @collection = new Backbone.Collection(@options.messages.getUniqDates())
      @render()

    setOlderMessagesLink: ->
      @ui.loadOlderMessagesLink.toggleClass('hidden', @isAllMessages())
      @ui.noMoreMessagesLabel.toggleClass('hidden', !@isAllMessages())

    isAllMessages: ->
      @options.chatInfo.chat_messages_count == @options.messages.length

    getChatMembers: ->
      _.map(@options.chatMembers.models, (chatMember) ->
        { id: chatMember.get('id'), type: chatMember.get('member_type') }
      )

    showChatDocument: (messageId, fileId) =>
      if @options.client
        Backbone.history.navigate("clients/#{@options.client.get('id')}/messages/#{messageId}/document", trigger: true)
      else if @options.workflow
        Backbone.history.navigate("workflows/#{@options.workflow.get('id')}/messages/#{messageId}/document", trigger: true)
      else if @options.contact
        Backbone.history.navigate("contacts/#{@options.contact.get('id')}/messages/#{messageId}/document", trigger: true)
      else
        Backbone.history.navigate("messaging/#{@options.chatId}/messages/#{messageId}/document", trigger: true)
