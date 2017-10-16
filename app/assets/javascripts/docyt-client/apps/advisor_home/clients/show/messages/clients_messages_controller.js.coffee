@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.Controller extends Marionette.Object

    showClientMessages: (clientId) ->
      client = @getClient(clientId)
      client.fetch().done =>
        @clientLayoutView = @getClientLayoutView()
        App.mainRegion.show(@clientLayoutView)

        clientSideMenuView = @getClientSideMenuView(client)
        @clientLayoutView.sideMenuRegion.show(clientSideMenuView)

        messagesLayoutView = @getMessagesLayoutView()
        @clientLayoutView.detailsRegion.show(messagesLayoutView)

        chatId = client.get('chat_id')

        if client.has('consumer_id')
          chat = @getChat(chatId)
          chat.fetch().done =>
            @messages = @getMessages()
            @messages.fetch(data: { chat_id: chat.get('id') }).done =>
              dates = new Backbone.Collection(@messages.getUniqDates())
              chatMembers = new Docyt.Entities.ChatMembers(chat.get('chat_members'))
              options =
                dates:  dates
                chatId: chatId
                client: client
                messages: @messages
                chatInfo: @messages.chatInfo
                chatMembers: chatMembers

              messagesHeaderMenuView = @getMessagesHeaderMenu(options)
              @clientLayoutView.headerMenuRegion.show(messagesHeaderMenuView)

              clientMessagesGroupsListView = @getClientMessagesGroupsList(options)
              messagesLayoutView.messagesRegion.show(clientMessagesGroupsListView)
        else
          chatWithUnconnectedClientView = @getUnconnectedClientView(client)
          messagesLayoutView.messagesRegion.show(chatWithUnconnectedClientView)

        messagesActionsBar = @getMessagesActionsBar(client, chatId)
        messagesLayoutView.actionsBarRegion.show(messagesActionsBar)

    showChatDocument: (clientId, messageId) =>
      message = @messages.get(messageId)
      document = message.get('chat_document')

      if document
        document = @getDocument(document)
        document.fetch().done =>
          documentView = @getDocumentView(document)
          @clientLayoutView.detailsRegion.show(documentView)

          if document.has('standard_document_id') && document.get('document_owners').length
            documentRightSideMenuView = @getDocumentRightSideMenuView()
            @clientLayoutView.rightSideRegion.show(documentRightSideMenuView)

            documentFields = @getDocumentFields()
            documentFields.fetch(url: "/api/web/v1/documents/#{document.get('id')}/document_fields").done =>
              documentFieldsView = @getDocumentFieldsView(documentFields, document.get('id'))
              documentRightSideMenuView.documentFieldsRegion.show(documentFieldsView)

              documentOwnersCollection = @getDocumentOwners(document.get('document_owners'))
              documentOwnersView = @getDocumentOwnersView(documentOwnersCollection)
              documentRightSideMenuView.documentOwnersRegion.show(documentOwnersView)
      else
        toastr.error('Document loading failed. Please try again later.', 'Something went wrong.')

    getChat: (chatId) ->
      new App.Entities.Chat(id: chatId)

    getClient: (clientId) ->
      new App.Entities.Client(id: clientId)

    getDocument: (attrs) ->
      new App.Entities.Document(attrs)

    getMessages: ->
      new App.Entities.Messages

    getDocumentFields: ->
      new App.Entities.DocumentFields

    getDocumentView: (document) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentView
        model: document

    getDocumentRightSideMenuView: ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.RightSideMenuLayout

    getDocumentFieldsView: (documentFields, documentId) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.Index.DocumentFieldsList
        collection: documentFields
        documentId: documentId

    getDocumentOwnersView: (documentOwners) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentOwners.Index.DocumentOwnersList
        collection: documentOwners

    getDocumentOwners: (collection) ->
      new App.Entities.DocumentOwners(collection)

    getMessagesGroupsList: ->
      new App.AdvisorHomeApp.Clients.Show.Messages.GroupsList

    getClientLayoutView: ->
      new App.AdvisorHomeApp.Clients.Show.Layout

    getMessagesLayoutView: ->
      new Messages.Layout

    getMessagesHeaderMenu: (options = {}) ->
      new Messages.HeaderMenu
        chatId:   options.chatId
        chatInfo: options.chatInfo
        messages: options.messages

    getClientSideMenuView: (client) ->
      new App.AdvisorHomeApp.Clients.Show.SideMenu
        model: client
        activeSubmenu: 'messages'

    getClientMessagesGroupsList: (options = {}) ->
      new Messages.GroupsList
        chatId:      options.chatId
        client:      options.client
        messages:    options.messages
        chatInfo:    options.chatInfo
        collection:  options.dates
        chatMembers: options.chatMembers

    getMessagesActionsBar: (client, chatId) ->
      new Messages.ActionsBar(client: client, chatId: chatId)

    getUnconnectedClientView: (client) ->
      new Messages.UnconnectedClientChatItemView(model: client)
