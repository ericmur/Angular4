@Docyt.module "Common.BaseStandardFolders.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Marionette.Object

    getDocument: (documentId) ->
      new Docyt.Entities.Document
        id: documentId

    getDocuments: ->
      new Docyt.Entities.Documents

    getStandardFolder: (categoryId) ->
      new Docyt.Entities.StandardFolder
        id: categoryId

    getDocumentFields: ->
      new Docyt.Entities.DocumentFields

    getStandardFolders: ->
      new Docyt.Entities.StandardFolders

    getDocumentOwners: (collection) ->
      new Docyt.Entities.DocumentOwners(collection)

    getDocumentShowLayoutView: ->
      new Docyt.AdvisorHomeApp.Documents.Layout

    getStandardFolderBoxesLayoutView: ->
      new Docyt.AdvisorHomeApp.StandardFolders.Index.BoxesLayout

    getStandardFoldersWithSideMenuLayoutView: ->
      new Docyt.AdvisorHomeApp.StandardFolders.Index.WithSideMenuLayout

    getDocumentRightSideMenuView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.RightSideMenuLayout

    getDocumentView: (document) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentView
        model: document

    getDocumentOwnersView: (documentOwners) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentOwners.Index.DocumentOwnersList
        collection: documentOwners

    getDocumentFieldsView: (documentId, documentFields) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.Index.DocumentFieldsList
        collection: documentFields
        documentId: documentId

    getHeaderStandardFoldersView: (opts = {}) ->
      new Docyt.AdvisorHomeApp.StandardFolders.HeaderMenu.Show.HeaderItemView
        sideMenu: opts.sideMenu
        business: opts.business

    getStandardFoldersListView: (standardFolders, business) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Index.StandardFoldersList
        business:     business
        collection:   standardFolders
        ownDocuments: true

    getStandardFoldersDetailsLayoutView: ->
      new Docyt.AdvisorHomeApp.StandardFolders.Show.Details.Layout

    getStandardFoldersSideMenuCollectionView: (standardFolders, currentCategoryId, business) ->
      new Docyt.AdvisorHomeApp.StandardFolders.Show.SideMenuCollection
        business:          business
        collection:        standardFolders
        currentCategoryId: currentCategoryId

    getConfirmPasswordModal: (options) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Show.ConfirmPasswordModal
        business:       options.business
        ownDocuments:   true
        standardFolder: options.standardFolder

    getDocumentsListView: (documents, business, standardFolder) ->
      new Docyt.AdvisorHomeApp.StandardFolders.Show.Documents.Index.DocumentsList
        business:       business
        collection:     documents
        standardFolder: standardFolder

    changeCategoriesView: (business) =>
      return @showBoxCategories() if @sideMenuCategoriesView

      @showWithSideMenu(business)

    getShowDocumentLayout: (business) ->
      if @sideMenuCategoriesView
        @showStandardFoldersWithSideMenuLayoutView()
        @checkStandardFolders(business)
        @standardFolderWithSideMenuLayout
      else
        @showDocumentLayoutView()
        @documentShowLayoutView

    showWithSideMenu: (business) ->
      @sideMenuCategoriesView = true

      @showStandardFoldersWithSideMenuLayoutView()
      @showStandardFoldersDetailsLayoutView()

      @showHeaderStandardFoldersView(@standardFoldersDetailsLayout, true)

      @checkStandardFolders(business)

      if @standardFolder && @documents.relevantCategory(@standardFolder)
        @displayCategoryDocumentsView(@documents, business: business, standardFolder: @standardFolder)

    showBoxCategories: ->
      @sideMenuCategoriesView = false

      @showStandardFoldersBoxesLayout()
      @standardFolderBoxesLayout.documentsCategoryRegion.reset()

      @showHeaderStandardFoldersView(@standardFolderBoxesLayout)

      documentsListView = @getDocumentsListView(@documents, @business, @standardFolder)
      @standardFolderBoxesLayout.documentsCategoryRegion.show(documentsListView)

      unless @standardFolder
        standardFoldersListView = @getStandardFoldersListView(@standardFolders, @business)
        @standardFolderBoxesLayout.categoriesBoxesRegion.show(standardFoldersListView)

    showDocumentLayoutView: ->
      @documentShowLayoutView = @getDocumentShowLayoutView()
      App.mainRegion.show(@documentShowLayoutView)

    showStandardFoldersBoxesLayout: ->
      @standardFolderBoxesLayout = @getStandardFolderBoxesLayoutView()
      App.mainRegion.show(@standardFolderBoxesLayout)

    showStandardFoldersWithSideMenuLayoutView: ->
      @standardFolderWithSideMenuLayout = @getStandardFoldersWithSideMenuLayoutView()
      App.mainRegion.show(@standardFolderWithSideMenuLayout)

    showStandardFoldersDetailsLayoutView: ->
      @standardFoldersDetailsLayout = @getStandardFoldersDetailsLayoutView()
      @standardFolderWithSideMenuLayout.categoryDetailsRegion.show(@standardFoldersDetailsLayout)

    showHeaderStandardFoldersView: (layout, sideMenu) ->
      headerStandardFoldersView = @getHeaderStandardFoldersView(sideMenu: sideMenu, business: @business)
      layout.headerMenuRegion.show(headerStandardFoldersView)

    showStandardFoldersSideMenuView: ->
      standardFoldersSideMenuCollectionView = @getStandardFoldersSideMenuCollectionView(@standardFolders, @getCurrentCategoryId(), @business)
      @standardFolderWithSideMenuLayout.sideMenuRegion.show(standardFoldersSideMenuCollectionView)

    showDocumentRightSideLayout: (layout) ->
      @documentRightSideMenuView = @getDocumentRightSideMenuView()
      layout.rightSideRegion.show(@documentRightSideMenuView)

    showDocumentFields: (documentId, documentFields) ->
      documentFieldsView = @getDocumentFieldsView(documentId, documentFields)
      @documentRightSideMenuView.documentFieldsRegion.show(documentFieldsView)

    showDocumentOwners: (document) ->
      documentOwnersCollection = @getDocumentOwners(document.get('document_owners'))
      documentOwnersView = @getDocumentOwnersView(documentOwnersCollection)
      @documentRightSideMenuView.documentOwnersRegion.show(documentOwnersView)

    showDocument: (document, region) ->
      region.show(@getDocumentView(document))

    checkStandardFolders: (business) ->
      return @showStandardFoldersSideMenuView() if @standardFolders

      @fetchStandardFolders(business).done => @showStandardFoldersSideMenuView()

    fetchDocumentFields: (documentId) ->
      documentFields = @getDocumentFields()
      documentFields.fetch(url: "/api/web/v1/documents/#{documentId}/document_fields").done =>
        @showDocumentFields(documentId, documentFields)

    fetchStandardFolders: (business) ->
      data = @setStandardFoldersParams(business)

      @standardFolders = @getStandardFolders()
      @standardFolders.fetch(data: data)

    fetchCategoryDocuments: (standardFolder, business) =>
      options =
        business:       business
        ownDocuments:   true
        standardFolder: standardFolder

      if standardFolder.get("id") == parseInt(configData.passwordCategory)
        @openConfirmPasswordModal(options)
      else
        @renderDocuments(options)

    fetchStandardFolder: (categoryId) ->
      @standardFolder = @getStandardFolder(categoryId)
      @standardFolder.fetch()

    renderDocuments: (options) =>
      data =
        password:      options.password
        business_id:   options.business.get('id') if options.business
        own_documents: true
        standard_folder_id: options.standardFolder.get('id')

      @documents = @getDocuments()
      @documents.fetch(data: data).success =>
        @displayCategoryDocumentsView(@documents, options)
      .error =>
        Docyt.vent.trigger('show:not:confirmed:password:on:secure:folder')

    openConfirmPasswordModal: (options) ->
      modalView = @getConfirmPasswordModal(options)
      Docyt.modalRegion.show(modalView)

    displayCategoryDocumentsView: (documents, options = {}) ->
      Docyt.vent.trigger('destroy:modal:confirmation:password:on:secure:folder')
      documentsListView = @getDocumentsListView(documents, options.business, options.standardFolder)

      if @sideMenuCategoriesView
        @standardFoldersDetailsLayout.containerRegion.show(documentsListView)
      else
        @standardFolderBoxesLayout.documentsCategoryRegion.show(documentsListView)

    getCurrentCategoryId: ->
      return unless @standardFolder

      @standardFolder.get('id')

    setStandardFoldersParams: (business) ->
      data =
        if business
          business_id: business.get('id')
        else
          own_categories: true
