@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.SelectCategory extends Marionette.ItemView
    template:  'advisor_home/workflows/index/create_workflow/workflows_index_select_category_tmpl'
    className: 'participants-docs-select'

    ui:
      categoryField:  '.categories-input-js'
      removeCategory: '.trash-icon-js'

    events:
      'click @ui.removeCategory': 'removeCategory'

    onRender: ->
      @initAutocomplete()

    removeCategory: ->
      @returnCategoryToCollection() unless @model.isNew()
      @model.collection.remove(@model)

    initAutocomplete: ->
      @selectizeSelect = @ui.categoryField.selectize(
        valueField:   'id'
        labelField:   'name'
        searchField:  ['name','category_name']
        sortField:    'category_name'
        create:       @createNewCategory
        options:      @options.item.get('categories').toJSON()
        render:
          item: (data, escape) =>
            @selectizeHtml(data, escape)
          option: (data, escape) =>
            @selectizeHtml(data, escape)
        onChange: (value) =>
          @setSelectedCategory(value) if value
        onFocus: =>
          @getCategoriesWithoutSelected()
        onDropdownClose: =>
          @removeCategoryFromDropDown()
      )
      @selectize = @selectizeSelect[0].selectize

    createNewCategory: (categoryName) =>
      newCategory =
        'id':   "#{_.uniqueId()}-userCreated"
        'name': categoryName

      @model.set('is_user_created_category', true)
      @model.set('category_name', newCategory['name'])

      Docyt.vent.trigger('categories:create:new', newCategory)
      newCategory

    selectizeHtml: (data, escape) ->
      data_name = if data.category_name then "#{data.category_name}:" else "MISC:"
      "<div class=\"item\" data-folder-id=\"#{data.standard_folder_id}\">#{data_name} #{data.name}</div>"

    setSelectedCategory: (categoryId) ->
      categoryId = parseInt(categoryId)
      category   = @getCategoryFromCollection(categoryId)

      if !@model.isNew() && @model.get('id') != categoryId
        @returnCategoryToCollection()

      @model.set(category.attributes)
      @removeCategoryFromCollection(categoryId)

    getCategoriesWithoutSelected: ->
      @selectize.clearOptions()

      if !@model.isNew()
        @returnCategoryToCollection()
        @selectize.addOption(@options.item.get('categories').toJSON())
        @selectize.addItem(@model.id)
      else
        @selectize.addOption(@options.item.get('categories').toJSON())

    returnCategoryToCollection: ->
      newCategory = new Docyt.Entities.StandardDocument(@model.attributes)
      @options.item.get('categories').add(newCategory)

    getCategoryFromCollection: (categoryId) ->
      category = @options.item.get('categories').get(categoryId)
      category.set(sendToBox: true, category_id: categoryId)
      category

    removeCategoryFromCollection: (categoryId) ->
      @options.item.get('categories').remove(categoryId)

    removeCategoryFromDropDown: ->
      unless @model.isNew()
        categoryInCollection = @options.item.get('categories').get(@model.get('id'))
        categoryInCollection.collection.remove(categoryInCollection) if categoryInCollection
