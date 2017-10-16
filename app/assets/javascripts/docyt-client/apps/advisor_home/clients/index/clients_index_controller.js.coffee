@Docyt.module "AdvisorHomeApp.Clients.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Marionette.Object

    showClients: (bizId) =>
      clients           = @getClients()
      clientsLayoutView = @getClientsIndexLayout()

      App.mainRegion.show(clientsLayoutView)

      clients.fetch().done =>
        options =
          clients: clients,
          bizId: bizId,
          pagesCount: clients.pagesCount

        clientsHeaderView   = @getClientsHeader(options)
        clientsSortMenuView = @getClientsSortMenu(options)

        clientsLayoutView.headerMenuRegion.show(clientsHeaderView)
        clientsLayoutView.headerSortRegion.show(clientsSortMenuView)

        clientsLayoutView.clientsListRegion.show(@getClientsListView(options))

    getClientsListView: (options = {}) ->
      new Index.ClientsList
        collection: options.clients,
        pagesCount: options.pagesCount,
        searchData: options.searchData

    getClients: ->
      new Docyt.Entities.Clients()

    getClientsHeader: (options = {}) ->
      new Index.ClientsHeader
        clients: options.clients
        bizId: options.bizId

    getClientsSortMenu: (options) ->
      new Index.SortMenu
        clients:  options.clients
        sortType: options.sortData

    getClientsIndexLayout: ->
      new Index.Layout()
