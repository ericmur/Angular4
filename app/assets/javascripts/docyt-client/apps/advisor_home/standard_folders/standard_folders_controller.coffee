@Docyt.module "AdvisorHomeApp.StandardFolders.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Docyt.Common.BaseStandardFolders.Index.Controller

    initialize: ->
      Docyt.vent.on('mydocuments:change:categories:view', @changeCategoriesView)
      Docyt.vent.on('mydocuments:load:documents:after:confirm:password', @renderDocuments)

    showStandardFolders: ->
      @fetchStandardFolders().done =>
        @documents = false
        @showBoxCategories()

    showCategoryDocuments: (categoryId) ->
      @fetchStandardFolder(categoryId).done =>

        if @sideMenuCategoriesView
          @showWithSideMenu()
        else
          @showStandardFoldersBoxesLayout()
          @showHeaderStandardFoldersView(@standardFolderBoxesLayout)

        @fetchCategoryDocuments(@standardFolder)

    showCategoryDocument: (categoryId, documentId) ->
      @fetchStandardFolder(categoryId).done =>
        document = @getDocument(documentId)
        document.fetch().done =>
          layout = @getShowDocumentLayout()
          @showDocument(document, layout.categoryDetailsRegion || layout.detailsRegion)

          if document.has('standard_document_id') && document.get('document_owners').length
            @showDocumentRightSideLayout(layout)
            @showDocumentOwners(document)
            @fetchDocumentFields(document.get('id'))
