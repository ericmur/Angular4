@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Clients extends Backbone.Collection
    model: Docyt.Entities.Client
    url: -> "/api/web/v1/clients"

    parse: (response) ->
      @pagesCount = response.meta.pages_count if response.meta
      response.clients

    fetchWithSearch: (options = {}) ->
      @fetch(
        url: '/api/web/v1/clients/search'
        data: { search_data: options.searchPhrase, fulltext_search: options.fullTextSearch }
      )
