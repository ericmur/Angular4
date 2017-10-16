@Docyt.module "AdvisorHomeApp.Workflows.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Marionette.Object

    showWorkflow: (workflowId) ->
      @workflowLayoutView ||= @getWorkflowLayout()
      App.mainRegion.show(@workflowLayoutView)

      workflows = @getWorkflows()
      workflows.fetch().done =>
        @workflowLayoutView.rightSideRegion.reset()

        workflow = workflows.get(workflowId)

        workflowSideMenuView = @getWorkflowSideMenuCollection(workflows, workflowId)
        @workflowLayoutView.sideMenuRegion.show(workflowSideMenuView)

        workflowDetailsLayoutView = @getWorkflowDetailsLayoutView()
        @workflowLayoutView.workflowDetailsRegion.show(workflowDetailsLayoutView)

        headerView = @getWorkflowDetailsHeader(workflow)
        workflowDetailsLayoutView.headerRegion.show(headerView)

        participantsCollectionView = @getParticipantsCollectionView(workflow)
        workflowDetailsLayoutView.participantsRegion.show(participantsCollectionView)

        chatId = workflow.get('chat_id')
        chat   = @getChat(chatId)

        chat.fetch().done =>
          @messages = @getMessages()

          @messages.fetch(url: "/api/web/v1/messages", data: { chat_id: chatId }).done =>
            dates = new Backbone.Collection(@messages.getUniqDates())
            chatMembers = new Docyt.Entities.ChatMembers(chat.get('chat_members'))
            options =
              dates: dates
              chatId: chatId
              messages: @messages
              chatInfo: @messages.chatInfo
              workflow: workflow
              chatMembers: chatMembers

            messagesLayoutView = @getMessagesLayoutView()
            workflowDetailsLayoutView.chatRegion.show(messagesLayoutView)

            messagesHeaderMenuView = @getMessagesHeaderMenu(options)
            messagesLayoutView.searchMessageRegion.show(messagesHeaderMenuView)

            clientMessagesGroupsListView = @getClientMessagesGroupsList(options)
            messagesLayoutView.messagesRegion.show(clientMessagesGroupsListView)

            messagesActionsBar = @getMessagesActionsBar(options.chatMembers, chatId)
            messagesLayoutView.actionsBarRegion.show(messagesActionsBar)

    showWorkflowDocument: (workflowId, messageId) ->
      message = @messages.get(messageId)
      document = message.get('chat_document')

      if document
        document = @getDocument(document)
        document.fetch(url: "/api/web/v1/documents/#{document.get('id')}").done =>
          documentView = @getDocumentView(document)
          @workflowLayoutView.workflowDetailsRegion.show(documentView)

          if document.has('standard_document_id') && document.get('document_owners').length > 0
            documentRightSideMenuView = @getDocumentRightSideMenuView()
            @workflowLayoutView.rightSideRegion.show(documentRightSideMenuView)

            documentFields = @getDocumentFields()
            documentFields.fetch(url: "/api/web/v1/documents/#{document.get('id')}/document_fields").done =>
              documentFieldsView = @getDocumentFieldsView(documentFields, document.get('id'))
              documentRightSideMenuView.documentFieldsRegion.show(documentFieldsView)

              documentOwnersCollection = @getDocumentOwners(document.get('document_owners'))
              documentOwnersView = @getDocumentOwnersView(documentOwnersCollection)
              documentRightSideMenuView.documentOwnersRegion.show(documentOwnersView)
      else
        toastr.error('Load document failed. Please try later.', 'Something went wrong.')

    getChat: (chatId) ->
      new App.Entities.Chat(id: chatId)

    getMessages: ->
      new App.Entities.Messages

    getWorkflows: ->
      new App.Entities.Workflows

    getWorkflowSideMenuCollection: (workflows, workflowId) ->
      new Show.WorkflowSideMenuCollection
        collection: workflows
        currentWorkflowId: workflowId

    getWorkflowLayout: ->
      new Show.WorkflowLayout

    getWorkflowDetailsLayoutView: ->
      new Show.Details.LayoutView

    getWorkflowDetailsHeader: (workflow) ->
      new Show.DetailsHeaderView
        model: workflow

    getParticipantsCollectionView: (workflow) ->
      new Show.ParticipantsCollectionView
        collection: workflow.get('participants')

    getMessagesLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Messages.Layout

    getMessagesHeaderMenu: (options = {}) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Messages.HeaderMenu
        chatId:   options.chatId
        chatInfo: options.chatInfo
        messages: options.messages

    getClientMessagesGroupsList: (options = {}) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Messages.GroupsList
        chatId:      options.chatId
        messages:    options.messages
        chatInfo:    options.chatInfo
        workflow:    options.workflow
        collection:  options.dates
        chatMembers: options.chatMembers

    getMessagesActionsBar: (chatMembers, chatId) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Messages.ActionsBar
        chatId:      chatId
        chatMembers: chatMembers

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

    getDocumentFields: ->
      new App.Entities.DocumentFields
