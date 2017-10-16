@Docyt.module "AdvisorHomeApp.LatestDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Marionette.Object

    showLatestDocuments: ->
      if Docyt.currentAdvisor.get('is_support')
        latestDocumentsLayout = @getLatestDocumentsLayout()
        App.mainRegion.show(latestDocumentsLayout)

        documents = @getDocuments()
        documents.fetch(data: @setDocumentParams()).done (response) =>
          pagesCount = response.meta.pages_count
          latestDocumentsCollectionView = @getLatestDocumentsCollectionView(documents, pagesCount)
          latestDocumentsLayout.documentsRegion.show(latestDocumentsCollectionView)
      else
        Backbone.history.navigate("/clients", trigger: true)

    getDocuments: ->
      new Docyt.Entities.Documents

    getLatestDocumentsLayout: ->
      new Docyt.AdvisorHomeApp.LatestDocuments.Index.Layout

    getLatestDocumentsCollectionView: (documents, pagesCount) ->
      new Docyt.AdvisorHomeApp.LatestDocuments.Index.DocumentsList
        pagesCount: pagesCount
        collection: documents

    setDocumentParams: ->
      data =
        per_page: 100
        for_support: true
        only_categorized: true

      data
