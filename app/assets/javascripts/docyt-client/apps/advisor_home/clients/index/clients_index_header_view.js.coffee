@Docyt.module "AdvisorHomeApp.Clients.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ClientsHeader extends Marionette.ItemView
    className: 'clients__search'
    template:  'advisor_home/clients/index/clients_index_header_tmpl'

    SEARCH_DEBOUNCE_INTERVAL = 500

    ui:
      searchField:     '.clients__search-input'
      addClientButton: '#add-client'
      clearSearchIcon: '.clients__search-clear'

    events:
      'keyup @ui.searchField' :    'onQueryChanged'
      'click @ui.addClientButton': 'openCreateClientModal'
      'click @ui.clearSearchIcon': 'clearInput'

    onShow: ->
      $('.header__dropdown-menu').find('a').removeClass('selected')
      $( "a[biz-id*='" + @options.bizId + "']" ).addClass("selected") if @options.bizId

    openCreateClientModal: ->
      modalView = new Docyt.AdvisorHomeApp.Clients.Index.CreateClientModal
        model: new Docyt.Entities.Client(type: 'Client')

      Docyt.modalRegion.show(modalView)

    onQueryChanged: _.debounce(
       -> @startSearch()
      SEARCH_DEBOUNCE_INTERVAL
    )

    startSearch: ->
      if $.trim(@ui.searchField.val()).length > 0
        @isChanged = true
        @ui.clearSearchIcon.show()
        Docyt.vent.trigger('show:spinner')

        searchData =
          fullTextSearch: @ui.searchField.val().replace(/[^a-zA-Z0-9_@\.]+/, '')

        @getSearchResult(searchData)

      else if @isChanged
        @isChanged = false
        Docyt.vent.trigger('show:spinner')
        @getDefaultClients()
        @ui.clearSearchIcon.hide()

    clearInput: ->
      @ui.searchField.val('')
      @startSearch()

    getSearchResult:(searchData) =>
      @options.clients.fetchWithSearch(searchData).success (response) =>
        $('.clients__main').highlight(searchData.fullTextSearch)
        Docyt.vent.trigger('hide:spinner')
      .error =>
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Search failed. Please try again.', 'Something went wrong!')

    getDefaultClients: ->
      @options.clients.fetch().success (response) =>
        Docyt.vent.trigger('hide:spinner')
        $('.clients__main').unhighlight()
      .error =>
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Load failed. Please try again.', 'Something went wrong!')
