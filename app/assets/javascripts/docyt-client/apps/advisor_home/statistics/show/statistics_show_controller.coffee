@Docyt.module "AdvisorHomeApp.Statistics.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Marionette.Object

    showStatistics: ->
      if Docyt.currentAdvisor.get('is_support')
        statisticsLayoutView = @getStatisticsLayout()

        App.mainRegion.show(statisticsLayoutView)

        categories = @getCategories()

        categories.fetch(data: { per_page: 100, for_support: true }).done (response) =>
          pagesCount = response.meta.pages_count
          categoriesCollection = @getDocumentTypesCollectionView(categories, pagesCount)
          statisticsLayoutView.documentTypesRegion.show(categoriesCollection)
      else
        Backbone.history.navigate("/clients", { trigger: true })

    getCategories: ->
      new Docyt.Entities.StandardDocuments

    getStatisticsLayout: ->
      new Show.Layout

    getDocumentTypesCollectionView: (categories, pagesCount) ->
      new Show.DocumentTypesList
        collection: categories
        pagesCount: pagesCount
