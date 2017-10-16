@Docyt.module "AdvisorHomeApp.Clients.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.SortMenu extends Marionette.ItemView
    className: 'clients__table-sort'
    template:  'advisor_home/clients/index/clients_index_sort_menu_tmpl'

    SORT_TYPES = ['Newest', 'Oldest', 'Unread Messages Count']

    ui:
      sortMenu:       '.clients__table-sort-menu'
      sortMenuItem:   '.clients__table-sort-menu-item'
      activeSortItem: '.main-select__toggle'

    events:
      'click @ui.sortMenuItem':   'orderClients'
      'click @ui.activeSortItem': 'showSortTypesList'

    templateHelpers: ->
      sortTypes: SORT_TYPES
      activeSortType: @options.sortType || _.first(SORT_TYPES)

    orderClients: (e) ->
      activeType  = $.trim(@ui.activeSortItem.text())
      sortingType = $.trim(e.currentTarget.textContent)

      if _.include(SORT_TYPES, sortingType) && activeType != sortingType
        Docyt.vent.trigger('show:spinner')

        @ui.activeSortItem.text(sortingType)
        @ui.sortMenu.hide()

        options =
          sortData: sortingType

        @getSortedClients(options)

    showSortTypesList: ->
      if @ui.sortMenu.is(':hidden') then @ui.sortMenu.show() else @ui.sortMenu.hide()

    getSortedClients: (options) ->
      @options.clients.fetch(data: { sort_method: options.sortData }).success (response) =>
        Docyt.vent.trigger('hide:spinner')
      .error =>
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Sorting failed. Please try again.', 'Something went wrong!')
