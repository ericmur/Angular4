@Docyt.module "AdvisorHomeApp.Contacts.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.Controller extends Marionette.Object

    showContactMessages: (contactId) ->
      contact = @getContact(contactId)
      contact.fetch().done =>
        @contactLayoutView = @getContactLayoutView()
        App.mainRegion.show(@contactLayoutView)

        sideMenuView = @getContactSideMenuView(contact)
        @contactLayoutView.sideMenuRegion.show(sideMenuView)

        messagesLayoutView = @getMessagesLayoutView()
        @contactLayoutView.detailsRegion.show(messagesLayoutView)

        chatId = contact.get('chat_id')

        if contact.has('user_id')
          chat = @getChat(chatId)
          chat.fetch().done =>
            @messages = @getMessages()
            @messages.fetch(data: { chat_id: chat.get('id') }).done =>
              dates = new Backbone.Collection(@messages.getUniqDates())
              chatMembers = new Docyt.Entities.ChatMembers(chat.get('chat_members'))
              options =
                dates:  dates
                chatId: chatId
                contact: contact
                messages: @messages
                chatInfo: @messages.chatInfo
                chatMembers: chatMembers

              messagesHeaderMenuView = @getMessagesHeaderMenu(options)
              @contactLayoutView.headerMenuRegion.show(messagesHeaderMenuView)

              contactMessagesGroupsListView = @getContactMessagesGroupsList(options)
              messagesLayoutView.messagesRegion.show(contactMessagesGroupsListView)
        else
          chatWithUnconnectedContactView = @getUnconnectedContactView(contact)
          messagesLayoutView.messagesRegion.show(chatWithUnconnectedContactView)

        messagesActionsBar = @getMessagesActionsBar(contact, chatId)
        messagesLayoutView.actionsBarRegion.show(messagesActionsBar)

    showChatDocument: (contactId, messageId) =>
      message = @messages.get(messageId)
      document = message.get('chat_document')

      if document
        document = @getDocument(document)
        document.fetch().done =>
          documentView = @getDocumentView(document)
          @contactLayoutView.detailsRegion.show(documentView)

          if document.has('standard_document_id') && document.get('document_owners').length
            documentRightSideMenuView = @getDocumentRightSideMenuView()
            @contactLayoutView.rightSideRegion.show(documentRightSideMenuView)

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

    getContact: (contactId) ->
      new App.Entities.Contact
        id: contactId

    getMessages: ->
      new App.Entities.Messages

    getDocument: (attrs) ->
      new App.Entities.Document(attrs)

    getDocumentFields: ->
      new App.Entities.DocumentFields

    getDocumentOwners: (collection) ->
      new App.Entities.DocumentOwners(collection)

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

    getContactLayoutView: ->
      new App.AdvisorHomeApp.Contacts.Show.Layout

    getContactSideMenuView: (contact) ->
      new App.AdvisorHomeApp.Clients.Show.SideMenu
        model: contact
        activeSubmenu: 'messages'

    getMessagesLayoutView: ->
      new App.AdvisorHomeApp.Contacts.Show.Messages.Layout

    getContactMessagesGroupsList: (options = {}) ->
      new App.AdvisorHomeApp.Clients.Show.Messages.GroupsList
        chatId:      options.chatId
        contact:     options.contact
        messages:    options.messages
        chatInfo:    options.chatInfo
        collection:  options.dates
        chatMembers: options.chatMembers

    getMessagesHeaderMenu: (options = {}) ->
      new App.AdvisorHomeApp.Clients.Show.Messages.HeaderMenu
        dates:    options.dates
        chatId:   options.chatId
        chatInfo: options.chatInfo
        messages: options.messages

    getMessagesActionsBar: (contact, chatId) ->
      new App.AdvisorHomeApp.Clients.Show.Messages.ActionsBar
        client: contact
        chatId: chatId

    getUnconnectedContactView: (contact) ->
      new App.AdvisorHomeApp.Clients.Show.Messages.UnconnectedClientChatItemView
        model: contact
