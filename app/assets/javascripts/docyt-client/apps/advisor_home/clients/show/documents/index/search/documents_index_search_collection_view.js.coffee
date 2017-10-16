@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentsSearchList extends Marionette.CompositeView
    template: 'advisor_home/clients/show/documents/index/search/clients_documents_search_list_tmpl'

    templateHelpers: ->
      resultSearchCount: @options.collection.length
      searchString: @options.searchData

    getChildView: ->
      Index.DocumentSearchItemView

    childViewOptions: ->
      client: @options.client
      isIndexPage: @options.isIndexPage

    attachBuffer: (collectionView, buffer) ->
      collectionView.$el.find('.client__docs-list').append(buffer)

    attachHtml: (collectionView, childView, index) ->
      return collectionView._bufferedChildren.splice(index, 0, childView) if collectionView.isBuffering

      if !collectionView._insertBefore(childView, index)
        collectionView.$el.find('.client__docs-list').append(childView.$el)

    onRender: ->
      @.$el.highlight(@options.searchData)
