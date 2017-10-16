@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentItemView extends Marionette.CompositeView
    childView: Index.DocumentFieldItemView
    tagName: -> @getTagName()
    className: 'client__docs-li'

    ui:
      trashcan:           '.icon-trashcan'
      fieldsList:         '.fields-list'
      editCategory:       '.icon-pencil'
      selectizeWrapper:   '.selectize-wrapper'
      openDocumentClass:  '.open-document'
      autocompleteSelect: '.file-category'

    events:
      'click @ui.trashcan':     'removeDocument'
      'click @ui.fieldsList':   'openDocumentFieldsModal'
      'click @ui.editCategory': 'toggleSelectize'

    getTagName: ->
      if @havePages() then 'tr' else 'tbody'

    getTemplate: ->
      if @havePages()
        'advisor_home/clients/show/documents/index/clients_documents_item_tmpl'
      else
        'advisor_home/clients/show/documents/index/clients_documents_item_without_pages_tmpl'

    templateHelpers: ->
      isIndexPage: @options.isIndexPage
      firstFourFields: @model.get('document_fields').slice(0,4) unless @havePages()
      categoryName: @model.get('standard_document').name if @model.get('standard_document')
      documentUrl: @model.getDocumentUrl(@options.client)
      truncatedDocumentName: @model.getTruncatedName(30)

    removeDocument: (e) =>
      e.stopPropagation()

      modalView = new Index.СonfirmationModal

      Docyt.modalRegion.show(modalView)

      modalView.on('confirm', =>
        @model.destroy().success =>
          Docyt.vent.trigger('file:destroy:success', @model)
        .error =>
          toastr.error('Delete failed. Please try again.', 'Something went wrong.')
        modalView.destroy()
      )

    toggleSelectize: (e) =>
      e.stopPropagation()
      if @isVisible then @hideSelectize() else @showSelectize()

    showSelectize: ->
      @toggleVisibility('show-selectize-block', 'hide-selectize-block')
      @isVisible = true

    hideSelectize: ->
      @toggleVisibility('hide-selectize-block', 'show-selectize-block')
      @isVisible = false

    toggleVisibility: (onClass, offClass) ->
      @ui.selectizeWrapper.removeClass(offClass)
      @ui.selectizeWrapper.addClass(onClass)

    openDocumentFieldsModal: =>
      collection = new Docyt.Entities.DocumentFields(@model.get('document_fields'))
      modalView = new Index.DocumentFieldsModal({ categoryName: @model.get('name'), collection: collection })
      Docyt.modalRegion.show(modalView)

    initialize: ->
      Docyt.vent.on('categories:loaded', @setAutocompleteOptions)
      Docyt.vent.on('categories:create:new', @addAutocompleteOption)
      @isVisible = false

    onDestroy: ->
      Docyt.vent.off('categories:loaded')
      Docyt.vent.off('categories:create:new')

    onRender: ->
      @initAutocomplete() if @havePages()
      @hideSelectize() unless @options.isIndexPage
      if @options.parentCollectionView.categories && @options.parentCollectionView.categories.length > 0
        @setAutocompleteOptions(@options.parentCollectionView.categories)

    insertFirstFields: (collectionView, itemView) =>
      if @$el.children().last().find('.action-icon-bar').length
        $(itemView.el).insertBefore(collectionView.$el.find('.action-icon-bar'))

    selectizeHtml: (data, escape) ->
      data_name = if data.category_name then "#{data.category_name}:" else "MISC:"
      "<div class=\"item\" data-folder-id=\"#{data.standard_folder_id}\">#{data_name} #{data.name}</div>"

    initAutocomplete: ->
      @selectizeSelect = @ui.autocompleteSelect.selectize(
        valueField:  'id'
        labelField:  'name'
        searchField: ['name','category_name']
        create:      @createNewCategory
        render:
          item: (data, escape) =>
            @selectizeHtml(data, escape)
          option: (data, escape) =>
            @selectizeHtml(data, escape)
        onChange: (value) =>
          @model.set('sendToBox', true)
          @model.set('category_id', value)
          @model.unset('is_user_created_category') if value == ''
          @updateCategory()
      )

    setAutocompleteOptions: (categories) =>
      return unless @havePages()

      categoriesJSON = categories.toJSON()
      @selectizeSelect[0].selectize.addOption(categoriesJSON) if categoriesJSON

    addAutocompleteOption: (category) =>
      @selectizeSelect[0].selectize.addOption(category)

    createNewCategory: (categoryName) =>
      newCategory =
        'id':   "#{_.uniqueId()}-userCreated"
        'name': categoryName

      @model.set('is_user_created_category', true)
      @model.set('category_name', newCategory['name'])

      Docyt.vent.trigger('categories:create:new', newCategory)
      newCategory

    updateCategory: ->
      is_user_created  = @model.get('is_user_created_category')
      category_id      = @model.get('category_id')
      standard_folder_id = $("[data-value=#{category_id}].item").data('folder-id') if category_id
      prev_category_id = "#{@model.get('standard_document').id}" if @model.get('standard_document')?
      if (category_id != '' && category_id != undefined && prev_category_id != category_id) || is_user_created

        @model.set(
          standard_document:
            id:   @model.get('category_id')
            name: @model.get('category_name')
            is_user_created: @model.get('is_user_created_category')
        )

        @model.updateCategory().success (response) =>
          standardDocument = response.document.standard_document
          if standardDocument.category_name == null && standardDocument.standard_folder_id == null && standardDocument.name?
            Docyt.vent.trigger('category:changed', parseInt(configData.miscCategory))
          else
            Docyt.vent.trigger('category:changed', standardDocument.standard_folder_id)

          @addDocument(@model, standardDocument)

    havePages: ->
      return true if !@model.has('standard_document') || !@model.get('standard_document').with_pages? || @options.isIndexPage
      @model.get('standard_document').with_pages

    isSecureFolder: ->
      @model.get('standard_document').standard_folder_id == configData.passwordCategory

    addDocument: (document, standardDocument) ->
      if @options.standardFolder && standardDocument.standard_folder_id == @options.standardFolder.get('id')
        @collection.add(document)
      else
        @model.collection.remove(@model) if @model.collection
