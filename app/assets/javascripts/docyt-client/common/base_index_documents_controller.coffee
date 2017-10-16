@Docyt.module "Common.BaseDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Marionette.Object

    searchDocuments: (params, client, searchPhrase) ->
      documents = @getDocuments()
      documents.fetchWithSearch(params).done =>
        searchDocumentsListView = @getSearchDocumentsList(documents, client, searchPhrase)
        @mainLayoutView.detailsRegion.show(searchDocumentsListView)

        @removeCurrentRegions()

    getContact: (contactId) ->
      new Docyt.Entities.Contact
        id: contactId

    getContacts: ->
      new Docyt.Entities.Contacts

    getDocuments: ->
      new Docyt.Entities.Documents

    getStandardFolders: ->
      new Docyt.Entities.StandardFolders

    getClientLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Layout

    getContactLayoutView: ->
      new Docyt.AdvisorHomeApp.Contacts.Show.Layout

    getSideMenuView: (client) ->
      new Docyt.AdvisorHomeApp.Clients.Show.SideMenu
        model: client
        activeSubmenu: 'documents'

    getSearchDocumentsList: (documents, client, searchPhrase) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.DocumentsSearchList
        client:      client
        searchData:  searchPhrase
        collection:  documents
        isIndexPage: false

    getDocumentsListView: (documents, client, contact, structureType) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.DocumentsList
        client:        client
        contact:       contact
        collection:    documents
        isIndexPage:   true
        structureType: structureType

    getHeaderMenuView: (options = {}) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.HeaderMenu
        client:  options.client
        contact: options.contact
        isIndexPage: options.isIndexPage

    getContactsListView: (contactsCollection, client) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.Contacts.Index.ContactsList
        client: client
        collection: contactsCollection

    getStandardFoldersListView: (standardFolders, client, contact = null) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Index.StandardFoldersList
        client:     client
        contact:    contact
        collection: standardFolders

    getDetailsContactsLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.Contacts.Layout

    getStandardFoldersWithSideMenuLayoutView: ->
      new Docyt.AdvisorHomeApp.StandardFolders.Index.WithSideMenuLayout

    getStandardFoldersDetailsLayoutView: ->
      new Docyt.AdvisorHomeApp.StandardFolders.Show.Details.Layout

    getHeaderStandardFoldersView: (opts = {}) ->
      new Docyt.AdvisorHomeApp.StandardFolders.HeaderMenu.Show.HeaderItemView
        client:   opts.client
        sideMenu: opts.sideMenu

    getStandardFoldersSideMenuCollectionView: (standardFolders) ->
      new Docyt.AdvisorHomeApp.StandardFolders.Show.SideMenuCollection
        collection: standardFolders

    removeCurrentRegions: ->
      if @mainLayoutView.categoriesBoxesRegion.currentView
        @mainLayoutView.categoriesBoxesRegion.currentView.destroy()

      if @mainLayoutView.detailsContactsRegion.currentView
        @mainLayoutView.detailsContactsRegion.currentView.destroy()

    baseRenderDocumentsAndFolders: (client, contact) ->
      if @mainLayoutView.detailsRegion.currentView
        @mainLayoutView.detailsRegion.currentView.destroy()
      if contact
        @baseRenderDocumentsAndFoldersForContact(client, contact)
      else
        @fetchContacts(client)

    baseRenderDocumentsAndFoldersForContact: (client, contact) =>
      options =
        client:  client
        contact: contact
        structureType: contact.get('get_structure_type')

      @fetchDocuments(options)

      @fetchStandardFolders(options) unless contact.get('get_structure_type') == 'flat'

    fetchContact: (client, contactId, contactType) ->
      contact = @getContact(contactId)
      contact.fetch(data: { contact_type: contactType }).done =>
        @showHeaderMenuView(client:  client, contact: contact, isIndexPage: false)
        @baseRenderDocumentsAndFoldersForContact(client, contact)

    fetchContacts: (client) ->
      contacts = @getContacts()
      contacts.fetch(data: @getContactsParams(client)).done =>
        @showHeaderMenuView(client: client, isIndexPage: contacts.length)

        if contacts.length
          @showContactsList(client: client, contacts: contacts)
        else
          @fetchDocuments(client: client, contact: client)
          @fetchStandardFolders(client: client, contact: client)

    fetchDocuments: (options = {}) ->
      data =
        contact_id:     options.contact.get('id')
        contact_type:   options.contact.get('type')
        structure_type: options.structureType

      @documents = @getDocuments()
      @documents.fetch(data: data).done =>
        @showDocumentsList(@documents, options.client, options.contact, options.structureType)

    fetchStandardFolders: (options = {}) ->
      @standardFolders = @getStandardFolders()
      @standardFolders.fetch(data: @standardFoldersParams(options.contact)).done =>
        @showStandardFolders(@standardFolders, options.client, options.contact)

    showDocumentsList: (documents, client, contact, structureType) ->
      documentsListView = @getDocumentsListView(documents, client, contact, structureType)
      @mainLayoutView.detailsRegion.show(documentsListView)

    showStandardFolders: (standardFolders, client, contact) ->
      standardFoldersListView = @getStandardFoldersListView(standardFolders, client, contact)
      @mainLayoutView.categoriesBoxesRegion.show(standardFoldersListView)

    showContactsList: (options = {}) ->
      contactsRegion = @mainLayoutView.detailsContactsRegion

      detailsContactsLayoutView = @getDetailsContactsLayoutView()
      contactsRegion.show(detailsContactsLayoutView)

      options.client.set(
        id: @parseClientId(options.client)
        get_label: 'Self'
        contact_id: options.client.get('id')
      )

      options.contacts.unshift(options.client)
      contactsListView = @getContactsListView(options.contacts, options.client)
      detailsContactsLayoutView.contactsList.show(contactsListView)

    showSideMenuView: (client) ->
      sideMenuView = @getSideMenuView(client)
      @mainLayoutView.sideMenuRegion.show(sideMenuView)

    showHeaderMenuView: (options) ->
      headerMenuView = @getHeaderMenuView(options)
      @mainLayoutView.headerMenuRegion.show(headerMenuView)

    showClientBoxCategories: (client, contact) ->
      structureType           = contact.get('get_structure_type') if @contact
      @sideMenuCategoriesView = false

      @showLayoutView(client)
      @showSideMenuView(client)

      @showHeaderMenuView(client: client, contact: contact, isIndexPage: false)
      @showDocumentsList(@documents, client, contact, structureType)
      @showStandardFolders(@standardFolders, client, contact) unless structureType == 'flat'

    showClientCategoriesWithSideMenu: (client) ->
      @sideMenuCategoriesView = true
      standardFolderWithSideMenuLayout = @getStandardFoldersWithSideMenuLayoutView()

      Docyt.mainRegion.show(standardFolderWithSideMenuLayout)

      standardFoldersDetailsLayout = @getStandardFoldersDetailsLayoutView()
      standardFolderWithSideMenuLayout.categoryDetailsRegion.show(standardFoldersDetailsLayout)

      headerStandardFoldersView = @getHeaderStandardFoldersView(client: client, sideMenu: true)
      standardFoldersDetailsLayout.headerMenuRegion.show(headerStandardFoldersView)

      standardFoldersSideMenuCollectionView = @getStandardFoldersSideMenuCollectionView(@standardFolders)
      standardFolderWithSideMenuLayout.sideMenuRegion.show(standardFoldersSideMenuCollectionView)

    showLayoutView: (client) ->
      @mainLayoutView = @checkClient(client)
      Docyt.mainRegion.show(@mainLayoutView)

    checkClient: (client) ->
      if client.get('type') == 'Client'
        @getClientLayoutView()
      else
        @getContactLayoutView()

    standardFoldersParams: (contact) ->
      data =
        contact_id:   contact.get('id')
        contact_type: contact.get('type')

      data

    getSearchParams: (params) ->
      searchData =
        contact_id:    params.contactId
        contact_type:  params.contactType
        search_data:   params.searchPhrase

      searchData

    getContactsParams: (client) ->
      if client.get('type') == 'Client'
        data = { client_id: client.get('id') }
      else
        data = { group_user_id: client.get('id') }

      data

    parseClientId: (client) ->
      if client.get('type') == 'Client'
        "#{client.get('id')}-Client" #Change id because Client.id and group_user.id could conflict and if they are the same backbone collection won't add duplicate model to the collection
      else
        client.get('id')
