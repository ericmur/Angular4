@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Marionette.Object

    initialize: ->
      Docyt.vent.on('category:search:documents', @listSearchResults)
      Docyt.vent.on('category:documents', @renderFolderDocuments)
      Docyt.vent.on('load:documents:after:confirm:password', @renderDocuments)

    showStandardFolderDocuments: (clientId, categoryId, contactId, contactType) ->
      client = @getClient(clientId)
      client.fetch().done =>
        @clientLayoutView = @getClientLayoutView()
        App.mainRegion.show(@clientLayoutView)

        standardFolder = @getStandardFolder(clientId, categoryId)
        standardFolder.fetch(data: { contact_id: contactId, contact_type: contactType }).done =>

          if contactId
            contact = @getContact(contactId)
            contact.fetch(data: { contact_type: contactType }).done =>
              @renderFolderDocuments(client, contact, standardFolder)
          else
            @renderFolderDocuments(client, null, standardFolder)

    listSearchResults: (searchData) =>
      params = @setSearchParams(searchData)
      client = @getClient(searchData.clientId)

      client.fetch().done =>
        documents = @getDocuments()
        documents.fetchWithSearch(params).done =>
          clientSearchDocumentsListView = @getClientSearchDocumentsList(documents, client, searchData.searchPhrase)
          @clientLayoutView.detailsRegion.show(clientSearchDocumentsListView)

    getClient: (clientId) ->
      new Docyt.Entities.Client
        id: clientId

    getContact: (contactId) ->
      new Docyt.Entities.Contact
        id: contactId

    getDocuments: ->
      new Docyt.Entities.Documents

    getStandardFolder: (clientId, categoryId) ->
      new Docyt.Entities.StandardFolder
        id: categoryId
        clientId: clientId

    getClientLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Layout()

    getConfirmPasswordModal: (options) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Show.ConfirmPasswordModal
        client:  options.client
        contact: options.contact
        standardFolder: options.standardFolder

    openConfirmPasswordModal: (options) ->
      modalView = @getConfirmPasswordModal(options)
      Docyt.modalRegion.show(modalView)

    getClientSearchDocumentsList: (documents, client, searchData) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.DocumentsSearchList
        client:      client
        searchData:  searchData
        collection:  documents
        isIndexPage: false

    getClientHeaderMenuView: (client, contact, standardFolder) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.HeaderMenu
        client:         client
        contact:        contact
        isIndexPage:    false
        standardFolder: standardFolder

    getClientSideMenuView: (client) ->
      new Docyt.AdvisorHomeApp.Clients.Show.SideMenu
        model: client
        activeSubmenu: 'documents'

    getClientDocumentsListView: (documents, options = {}) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.DocumentsList
        client:         options.client
        contact:        options.contact
        collection:     documents
        isIndexPage:    false
        standardFolder: options.standardFolder

    renderDocuments: (options) =>
      data =
        password:     options.password
        contact_id:   options.contact.get('id')
        contact_type: options.contact.get('type')
        standard_folder_id: options.standardFolder.get('id')

      documents = @getDocuments()
      documents.fetch(data: data).success =>
        clientDocumentsListView = @getClientDocumentsListView(documents, options)
        @clientLayoutView.detailsRegion.show(clientDocumentsListView)
        Docyt.vent.trigger('destroy:modal:confirmation:password:on:secure:folder')
      .error =>
        Docyt.vent.trigger('show:not:confirmed:password:on:secure:folder')

    renderFolderDocuments: (client, contact, standardFolder) =>
      clientHeaderMenuView = @getClientHeaderMenuView(client, contact, standardFolder)
      clientSideMenuView   = @getClientSideMenuView(client)

      @clientLayoutView.headerMenuRegion.show(clientHeaderMenuView)
      @clientLayoutView.sideMenuRegion.show(clientSideMenuView)

      options =
        client: client
        contact: contact
        standardFolder: standardFolder

      if standardFolder.get("id") == parseInt(configData.passwordCategory)
        @openConfirmPasswordModal(options)
      else
        @renderDocuments(options)

    setSearchParams: (params) ->
      searchData =
        client_id:     params.clientId
        contact_id:    params.contactId
        contact_type:  params.contactType
        search_data:   params.searchPhrase

      searchData
