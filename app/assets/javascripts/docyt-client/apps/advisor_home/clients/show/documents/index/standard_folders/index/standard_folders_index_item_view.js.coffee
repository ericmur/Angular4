@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.StandardFolderItemView extends Marionette.ItemView
    tagClass: 'div'
    className: 'client__documents-category-wrapper grid-item'
    template: 'advisor_home/clients/show/documents/standard_folders/index/standard_folders_item_tmpl'

    DEFAULT_ICON_DPI = '3x'

    ui:
      categoryBoxWrapper: '.client__documents-category-content'

    events:
      'drop @ui.categoryBoxWrapper': 'uploadFilesForCategory'

    templateHelpers: ->
      iconUrl: @getStandardFolderIcon()
      categoryDocumentsUrl: @getCategoryDocumentUrl()

    initialize: ->
      Docyt.vent.on('category:changed', @updateCounter)
      Docyt.vent.on('standard:folders:list:highlight', @toggleHighlight)
      @client   = @options.client
      @contact  = @options.contact
      @business = @options.business

    onDestroy: ->
      Docyt.vent.off('category:changed')
      Docyt.vent.off('standard:folders:list:highlight')

    getStandardFolderIcon: (size = DEFAULT_ICON_DPI)->
      @model.getIconS3Url(size)

    getCategoryDocumentUrl: ->
      return @checkOptions() unless @contact || @client

      contactId   = if @contact then @contact.get('id')   else @client.get('id')
      contactType = if @contact then @contact.get('type') else 'Client'

      @getCategoriesUrl(contactId, contactType)

    updateCounter: (standardFolderId) =>
      return unless standardFolderId == @model.get('id')

      @model.set('documents_count', @model.get('documents_count') + 1)
      @render()

    getCategoriesUrl: (contactId, contactType) ->
      entity = if @client.get('type') == 'Client' then 'clients' else 'contacts'

      "/#{entity}/#{@client.get('id')}/categories/#{@model.get('id')}/documents/#{contactId}/#{contactType}"

    checkOptions: ->
      if @business
        "businesses/#{@business.get('id')}/standard_folders/#{@model.get('id')}"
      else if @options.ownDocuments
        "my_documents/#{@model.get('id')}"
      else
        '#'

    toggleHighlight: (value) =>
      @ui.categoryBoxWrapper.toggleClass('drop__zone_active', value)

    uploadFilesForCategory: (e) ->
      return unless @allowedList()

      e.preventDefault()
      e.stopPropagation()
      e.originalEvent.dataTransfer.dropEffect = 'copy'

      Docyt.vent.trigger('standard:folders:list:highlight', false)

      modalView = new Docyt.AdvisorHomeApp.Businesses.Show.StandardFolders.Index.DocumentsUploadModalWithCategoryView
        files:   new Docyt.Services.DragAndDropFileUploadHelper(e).getFilesFromEvent()
        clients: @collection.models

      Docyt.modalRegion.show(modalView)

    allowedList: ->
      @business || @options.ownDocuments
