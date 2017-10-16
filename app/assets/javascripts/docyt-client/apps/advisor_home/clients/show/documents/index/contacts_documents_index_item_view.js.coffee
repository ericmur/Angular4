@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ContactDocumentItemView extends Marionette.ItemView
    tagName:   'tr'
    className: 'client__docs-li'
    template:  'advisor_home/clients/show/documents/index/clients_contacts_documents_item_tmpl'

    ui:
      trashcan:           '.icon-trashcan'
      editCategory:       '.icon-pencil'
      selectizeWrapper:   '.selectize-wrapper'
      openDocumentClass:  '.open-document'
      autocompleteSelect: '.file-category'

    events:
      'click @ui.trashcan':          'removeDocument'
      'click @ui.editCategory':      'toggleSelectize'
      'click @ui.openDocumentClass': 'openDocument'

    templateHelpers: ->
      isIndexPage: @isIndexPage
      documentName: @getDocumentName()
      documentUrl: "/clients/#{@options.client.get('id')}/documents/#{@model.get('id')}"

    getDocumentName: ->
      if @model.has('standard_folder_name') && @model.has('standard_document_name')
        "#{@model.get('standard_folder_name')}/#{@model.get('standard_document_name')}"
      else
        @model.getTruncatedName(30)

    initialize: ->
      @listenTo(@model, 'change', @render)
      Docyt.vent.on('categories:loaded', @setAutocompleteOptions)
      Docyt.vent.on('categories:create:new', @addAutocompleteOption)
      @isIndexPage = @options.isIndexPage
      @isVisible = !(@model.has('standard_document'))

    toggleSelectize: (e) =>
      e.stopPropagation()
      if @isVisible
        @.$el.removeClass('hover-row')
        @hideSelectize()
      else
        @.$el.addClass('hover-row')
        @showSelectize()

    showSelectize: ->
      @toggleVisibility('show-selectize-block', 'hide-selectize-block')
      @isVisible = true

    hideSelectize: ->
      @toggleVisibility('hide-selectize-block', 'show-selectize-block')
      @isVisible = false

    toggleVisibility: (onClass, offClass) ->
      @ui.selectizeWrapper.removeClass(offClass)
      @ui.selectizeWrapper.addClass(onClass)

    onRender: ->
      @initAutocomplete()
      @initSelectCategory()
      if @options.parentCollectionView.categories && @options.parentCollectionView.categories.length > 0
        @setAutocompleteOptions(@options.parentCollectionView.categories)

    onDestroy: ->
      Docyt.vent.off('categories:loaded')
      Docyt.vent.off('categories:create:new')

    initSelectCategory: ->
      if @model.has('standard_document')
        @hideSelectize()
      else
        @showSelectize()

    initAutocomplete: ->
      @selectizeSelect = @ui.autocompleteSelect.selectize(
        valueField:  'id'
        labelField:  'name'
        searchField: 'name'
        create:      @createNewCategory
        render:
          item: (data, escape) ->
            "<div class=\"item\" data-folder-id=\"#{data.standard_folder_id}\">#{data.name}</div>"
        onChange: (value) =>
          @model.set('sendToBox', true)
          @model.set('category_id', value)
          @model.unset('is_user_created_category') if value == ''
          @updateCategory()
      )

    setAutocompleteOptions: (categories) =>
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

        @model.updateCategory()
        @.$el.removeClass('hover-row')

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

    openDocument: =>
      Backbone.history.navigate("/clients/#{@options.client.get('id')}/documents/#{@model.get('id')}", { trigger: true })
