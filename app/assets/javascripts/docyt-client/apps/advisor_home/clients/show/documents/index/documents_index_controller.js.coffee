@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Docyt.Common.BaseDocuments.Index.Controller

    initialize: ->
      Docyt.vent.on('search:documents', @listSearchResults)
      Docyt.vent.on('list:documents', @renderDocumentsAndFolders)
      Docyt.vent.on('client:change:categories:view', @changeCategoriesView)

    listSearchResults: (searchData) =>
      params = @getSearchParams(searchData)
      client = @getClient(searchData.clientId)

      client.fetch().done =>
        @searchDocuments(params, client, searchData.searchPhrase)

    showClientDetailsDocuments: (clientId) ->
      @client = @getClient(clientId)
      @client.fetch().done =>
        @showLayoutView(@client)
        @showSideMenuView(@client)
        @renderDocumentsAndFolders(@client)

    renderDocumentsAndFolders: (client, contact) =>
      @baseRenderDocumentsAndFolders(client, contact)

    showClientDetailsDocumentsContacts: (clientId, contactId, contactType) ->
      @client = @getClient(clientId)
      @client.fetch().done =>
        @showLayoutView(@client)
        @showSideMenuView(@client)
        @fetchContact(@client, contactId, contactType)

    getClient: (clientId) ->
      new Docyt.Entities.Client
        id: clientId

    changeCategoriesView: =>
      return @showClientBoxCategories(@client, @contact) if @sideMenuCategoriesView

      @showClientCategoriesWithSideMenu(@client)
