@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.SortMenu extends Marionette.ItemView
    className: 'clients__table-sort'
    template:  'advisor_home/workflows/index/workflows_index_sort_menu_tmpl'

    SORT_TYPES = ['Last messages', 'Oldest']

    ui:
      sortMenu:       '.clients__table-sort-menu'
      activeSortItem: '.main-select__toggle'

    events:
      'click @ui.activeSortItem': 'showSortTypesList'

    templateHelpers: ->
      sortTypes: SORT_TYPES
      activeSortType: @options.sortType || _.first(SORT_TYPES)

    showSortTypesList: ->
      if @ui.sortMenu.is(':hidden') then @ui.sortMenu.show() else @ui.sortMenu.hide()
