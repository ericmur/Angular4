@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.HeaderMenu extends Marionette.ItemView
    template: 'advisor_home/clients/show/documents/index/clients_documents_header_menu_tmpl'

    SEARCH_DEBOUNCE_INTERVAL = 500

    ui:
      toggleView:  '.toggle-categoires-view-js'
      searchIcon:  '.clients__search-clear'
      searchField: '.clients__search-input'

    events:
      'click @ui.searchIcon':  'clearInput'
      'click @ui.toggleView':  'toggleCategoriesView'
      'keyup @ui.searchField': 'onQueryChanged'

    onQueryChanged: _.debounce(
      -> @startSearch()
      SEARCH_DEBOUNCE_INTERVAL
    )

    initialize: ->
      @client  = @options.client
      @contact = @options.contact

    templateHelpers: ->
      backUrl:      @client.get('documentsUrl')
      isIndexPage:  @options.isIndexPage
      contactName:  @getContactName()
      contactLabel: @getContactLabel()

      clientHaveContacts: @client.hasContacts()
      standardFolderName: @options.standardFolder.get('name') if @options.standardFolder

    clearInput: ->
      @ui.searchField.val('')
      @startSearch()

    startSearch: ->
      clearSearchPhraseSize = $.trim(@ui.searchField.val()).length

      @ui.toggleView.toggleClass('hidden', clearSearchPhraseSize)
      @ui.searchIcon.toggleClass('hidden', !clearSearchPhraseSize)

      return @defaultDocuments() unless clearSearchPhraseSize

      searchData = @setSearchParams()
      @searchDocuments(searchData)

    searchDocuments: (searchData) =>
      if @options.hasOwnProperty('standardFolder')
        Docyt.vent.trigger(@client.get('searchDocumentsCategory'), searchData)
      else
        Docyt.vent.trigger(@client.get('searchAllDocuments'), searchData)

    defaultDocuments: =>
      if @options.hasOwnProperty('standardFolder')
        Docyt.vent.trigger(@client.get('categoryDocuments'), @client, @contact, @options.standardFolder)
      else
        Docyt.vent.trigger(@client.get('listAllDocuments'), @client, @contact)

    toggleCategoriesView: ->
      if @client.get('type') == 'Client'
        Docyt.vent.trigger('client:change:categories:view')
      else
        Docyt.vent.trigger('contact:change:categories:view')

    setSearchParams: ->
      searchData =
        clientId:     @client.get('id')
        contactId:    if @contact then @contact.get('id') else @client.get('id')
        contactType:  if @contact then @contact.get('type') else @client.get('type')
        searchPhrase: @ui.searchField.val().replace(/[^a-zA-Z0-9_]+/, '')

      searchData

    getContactName: ->
      return @contact.get('parsed_fullname') if @contact

      @client.get('parsed_fullname')

    getContactLabel: ->
      return @contact.get('get_label') if @contact

      @client.get('type')
