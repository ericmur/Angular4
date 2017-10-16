@Docyt.module "AdvisorHomeApp.Contacts.Show.Documents.Index.StandardFolders.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Marionette.Object

    initialize: ->
      Docyt.vent.on('contact:category:documents', @renderFolderDocuments)
      Docyt.vent.on('contact:category:search:documents', @listSearchResults)
      Docyt.vent.on('contact:load:documents:after:confirm:password', @fetchDocuments)

    showStandardFolderDocuments: (contactId, categoryId, subContactId, contactType) ->
      contact = @getContact(contactId)
      contact.fetch().done =>
        @showContactLayoutView()

        standardFolder = @getStandardFolder(categoryId)
        standardFolder.fetch(data: { contact_id: subContactId, contact_type: contactType }).done =>
          options = { contact: contact, standardFolder: standardFolder }

          if subContactId
            @checkSubContact(subContactId, options)
          else
            @renderFolderDocuments(options)

    listSearchResults: (searchData) =>
      params  = @setSearchParams(searchData)
      contact = @getContact(searchData.clientId)

      contact.fetch().done =>
        documents = @getDocuments()
        documents.fetchWithSearch(params).done =>
          contactSearchDocumentsListView = @getContactSearchDocumentsList(documents, contact, searchData.searchPhrase)
          @contactLayoutView.detailsRegion.show(contactSearchDocumentsListView)

    getContact: (contactId) ->
      new App.Entities.Contact
        id: contactId

    getStandardFolder: (categoryId) ->
      new App.Entities.StandardFolder
        id: categoryId

    getDocuments: ->
      new App.Entities.Documents

    getContactLayoutView: ->
      new App.AdvisorHomeApp.Contacts.Show.Layout

    openConfirmPasswordModal: (options) ->
      modalView = @getConfirmPasswordModal(options)
      Docyt.modalRegion.show(modalView)

    getConfirmPasswordModal: (options) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Show.ConfirmPasswordModal
        client: options.contact
        subContact:     options.subContact
        standardFolder: options.standardFolder

    getContactSearchDocumentsList: (documents, contact, searchData) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Index.DocumentsSearchList
        client:      contact
        searchData:  searchData
        collection:  documents
        isIndexPage: false

    getContactHeaderMenuView: (options = {}) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Index.HeaderMenu
        client:  options.contact
        contact: options.subContact
        isIndexPage:    false
        standardFolder: options.standardFolder

    getContactSideMenuView: (contact) ->
      new App.AdvisorHomeApp.Clients.Show.SideMenu
        model: contact
        activeSubmenu: 'documents'

    getContactDocumentsListView: (documents, options = {}) ->
      new App.AdvisorHomeApp.Clients.Show.Documents.Index.DocumentsList
        client:      options.client || options.contact
        contact:     options.subContact
        collection:  documents
        isIndexPage: false

    fetchDocuments: (options) =>
      data =
        password:     options.password
        contact_id:   options.subContact.get('id')
        contact_type: options.subContact.get('type')
        standard_folder_id: options.standardFolder.get('id')

      documents = @getDocuments()
      documents.fetch(data: data).success =>
        Docyt.vent.trigger('destroy:modal:confirmation:password:on:secure:folder')
        @showContactDocumentsList(documents, options)
      .error =>
        Docyt.vent.trigger('show:not:confirmed:password:on:secure:folder')

    renderFolderDocuments: (options = {}) =>
      @showContactHeaderMenu(options)
      @showContactSideMenu(options.contact)

      if options.standardFolder.get("id") == parseInt(configData.passwordCategory)
        @openConfirmPasswordModal(options)
      else
        @fetchDocuments(options)

    checkSubContact: (subContactId, options = {}) ->
      if parseInt(options.contact.get('id')) == parseInt(subContactId)
        options.subContact = options.contact
        @renderFolderDocuments(options)
      else
        subContact = @getContact(subContactId)
        subContact.fetch().done =>
          options.subContact = subContact
          @renderFolderDocuments(options)

    showContactLayoutView: ->
      @contactLayoutView = @getContactLayoutView()
      App.mainRegion.show(@contactLayoutView)

    showContactHeaderMenu: (options) ->
      contactHeaderMenuView = @getContactHeaderMenuView(options)
      @contactLayoutView.headerMenuRegion.show(contactHeaderMenuView)

    showContactSideMenu: (contact) ->
      contactSideMenuView = @getContactSideMenuView(contact)
      @contactLayoutView.sideMenuRegion.show(contactSideMenuView)

    showContactDocumentsList: (documents, options) ->
      contactDocumentsListView = @getContactDocumentsListView(documents, options)
      @contactLayoutView.detailsRegion.show(contactDocumentsListView)

    setSearchParams: (params) ->
      searchData =
        client_id:     params.clientId
        contact_id:    params.contactId
        contact_type:  params.contactType
        search_data:   params.searchPhrase

      searchData
