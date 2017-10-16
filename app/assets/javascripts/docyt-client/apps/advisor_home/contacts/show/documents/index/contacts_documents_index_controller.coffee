@Docyt.module "AdvisorHomeApp.Contacts.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Docyt.Common.BaseDocuments.Index.Controller

    initialize: ->
      Docyt.vent.on('contact:list:documents',   @renderDocumentsAndFolders)
      Docyt.vent.on('contact:search:documents', @listSearchResults)
      Docyt.vent.on('contact:change:categories:view', @changeCategoriesView)

    listSearchResults: (searchData) =>
      params  = @getSearchParams(searchData)
      contact = @getContact(searchData.clientId)

      contact.fetch().done =>
        @searchDocuments(params, contact, searchData.searchPhrase)

    renderDocumentsAndFolders: (contact, subContact) =>
      @baseRenderDocumentsAndFolders(contact, subContact)

    showContactDetailsDocuments: (contactId) ->
      @contact = @getContact(contactId)
      @contact.fetch().done =>
        @showLayoutView(@contact)
        @showSideMenuView(@contact)
        @fetchContacts(@contact)

    showContactDetailsDocumentsContacts: (contactId, subContactId, contactType) ->
      @contact = @getContact(contactId)
      @contact.fetch().done =>
        @showLayoutView(@contact)
        @showSideMenuView(@contact)

        if parseInt(contactId) == parseInt(subContactId)
          @showHeaderMenuView(client:  @contact, isIndexPage: false)
          @baseRenderDocumentsAndFoldersForContact(@contact, @contact)
        else
          @fetchContact(@contact, subContactId, contactType)

    changeCategoriesView: =>
      return @showContactBoxCategories(@contact, ) if @sideMenuCategoriesView

      @showContactCategoriesWithSideMenu()
