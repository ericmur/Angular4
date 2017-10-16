@Docyt.module "AdvisorHomeApp.Messaging.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Marionette.Object

    showMessaging: ->
      @messagingLayout = @getMessagingLayout()
      App.mainRegion.show(@messagingLayout)

      @chats ||= @getChats()
      @chats.fetch().done =>

        if @chats.length > 0
          firstChat = @chats.first()
          @showSideMenu(@chats, firstChat.get('id'))
          @fetchMessages(firstChat)

    showChat: (chatId) ->
      @messagingLayout ||= @getMessagingLayout()
      App.mainRegion.show(@messagingLayout)

      @chats ||= @getChats()
      @chats.fetch().done =>
        chat = @chats.get(chatId)
        chat.set('unread_messages_count', 0)
        @showSideMenu(@chats, chatId) if @chats.length > 0

        @messagingLayout.rightSideRegion.reset()
        @fetchMessages(chat)

    showChatDocument: (chatId, messageId) ->
      message = @messages.get(messageId)
      document = message.get('chat_document')

      if document
        document = @getDocument(document)
        document.fetch(url: "/api/web/v1/documents/#{document.get('id')}").done =>
          documentView = @getDocumentView(document)
          @messagingLayout.chatRegion.show(documentView)

          if document.has('standard_document_id') && document.get('document_owners').length > 0
            documentRightSideMenuView = @getDocumentRightSideMenuView()
            @messagingLayout.rightSideRegion.show(documentRightSideMenuView)

            documentFields = @getDocumentFields()
            documentFields.fetch(url: "/api/web/v1/documents/#{document.get('id')}/document_fields").done =>
              documentFieldsView = @getDocumentFieldsView(documentFields, document.get('id'))
              documentRightSideMenuView.documentFieldsRegion.show(documentFieldsView)

              documentOwnersCollection = @getDocumentOwners(document.get('document_owners'))
              documentOwnersView = @getDocumentOwnersView(documentOwnersCollection)
              documentRightSideMenuView.documentOwnersRegion.show(documentOwnersView)
      else
        toastr.error('Load document failed. Please try later.', 'Something went wrong.')

    showSideMenu: (chats, currentChatId) ->
      chatsSideMenuView = @getChatsSideMenuCollection(chats, currentChatId)
      @messagingLayout.sideMenuRegion.show(chatsSideMenuView)

    fetchMessages: (chat) ->
      chatId   = chat.get('id')
      @messages = @getMessages()

      @messages.fetch(url: "/api/web/v1/messages", data: { chat_id: chatId }).done =>
        dates = new Backbone.Collection(@messages.getUniqDates())
        chatMembers = new Docyt.Entities.ChatMembers(chat.get('chat_members'))

        options =
          chat:  chat
          dates: dates
          messages: @messages
          chatInfo: @messages.chatInfo
          chatMembers: chatMembers

        @messagesLayoutView = @getMessagesLayoutView()
        @messagingLayout.chatRegion.show(@messagesLayoutView)

        chatHeaderView = @getChatHeaderView(options)
        @messagesLayoutView.searchMessageRegion.show(chatHeaderView)

        clientMessagesGroupsListView = @getClientMessagesGroupsList(options)
        @messagesLayoutView.messagesRegion.show(clientMessagesGroupsListView)

        messagesActionsBar = @getMessagesActionsBar(options.chatMembers, chatId)
        @messagesLayoutView.actionsBarRegion.show(messagesActionsBar)

    getDocumentFields: ->
      new App.Entities.DocumentFields

    getMessages: ->
      new App.Entities.Messages

    getChats: ->
      new App.Entities.Chats

    getChatHeaderView: (options) ->
      new Show.MessagingHeaderItem
        chat:        options.chat
        chatInfo:    options.chatInfo
        messages:    options.messages
        chatMembers: options.chatMembers

    getMessagingLayout: ->
      new Show.MessagingLayout

    navigateToClientChat: (clientId) ->
      Backbone.history.navigate("/messaging/#{clientId}", trigger: true)

    getMessagesLayoutView: ->
      new App.AdvisorHomeApp.Clients.Show.Messages.Layout

    getMessagesActionsBar: (chatMembers, chatId) ->
      new App.AdvisorHomeApp.Clients.Show.Messages.ActionsBar
        chatId:      chatId
        chatMembers: chatMembers

    getClientMessagesGroupsList: (options = {}) ->
      new App.AdvisorHomeApp.Clients.Show.Messages.GroupsList
        chatId:      options.chat.get('id')
        messages:    options.messages
        chatInfo:    options.chatInfo
        collection:  options.dates
        chatMembers: options.chatMembers

    getChatsSideMenuCollection: (chats, currentChatId) ->
      new Show.MessagingSideMenuCollection
        collection:    chats
        currentChatId: currentChatId

    getDocument: (attrs) ->
      new App.Entities.Document(attrs)

    getDocumentView: (document) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentView
        model: document

    getDocumentRightSideMenuView: ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.RightSideMenuLayout

    getDocumentFieldsView: (documentFields, documentId) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.Index.DocumentFieldsList
        collection: documentFields
        documentId: documentId

    getDocumentOwners: (collection) ->
      new App.Entities.DocumentOwners(collection)

    getDocumentOwnersView: (documentOwners) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentOwners.Index.DocumentOwnersList
        collection: documentOwners
