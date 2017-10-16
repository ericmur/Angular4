@Docyt.module "AdvisorHomeApp.Businesses.Show.StandardFolders.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Docyt.Common.BaseStandardFolders.Index.Controller

    initialize: ->
      Docyt.vent.on('business:documents:change:categories:view', @changeCategoriesView)
      Docyt.vent.on('business:documents:load:documents:after:confirm:password', @renderDocuments)

    showBusinessStandardFolders: (businessId) ->
      @fetchBusiness(businessId).done =>
        @fetchStandardFolders(@business).done =>
          @fetchDocuments().done =>
            @standardFolder = false
            @showBoxCategories()

    showBusinessCategoryDocuments: (businessId, categoryId) ->
      @fetchBusiness(businessId).done =>
        @fetchStandardFolder(categoryId).done =>

          if @sideMenuCategoriesView
            @showWithSideMenu(@business)
          else
            @showStandardFoldersBoxesLayout()
            @showHeaderStandardFoldersView(@standardFolderBoxesLayout)

          @fetchCategoryDocuments(@standardFolder, @business)

    showBusinessCategoryDocument: (businessId, categoryId, documentId) ->
      @fetchBusiness(businessId).done =>
        @fetchStandardFolder(categoryId).done =>
          document = @getDocument(documentId)
          document.fetch().done =>
            layout = @getShowDocumentLayout(@business)
            @showDocument(document, layout.categoryDetailsRegion || layout.detailsRegion)

            if document.has('standard_document_id') && document.get('document_owners').length
              @showDocumentRightSideLayout(layout)
              @showDocumentOwners(document)
              @fetchDocumentFields(document.get('id'))

    getBusiness: (businessId) ->
      new Docyt.Entities.Business(id: businessId)

    fetchBusiness: (businessId) ->
      @business = @getBusiness(businessId)
      @business.fetch()

    fetchDocuments: ->
      @documents = @getDocuments()
      @documents.fetch(data: { business_id: @business.get('id') })
