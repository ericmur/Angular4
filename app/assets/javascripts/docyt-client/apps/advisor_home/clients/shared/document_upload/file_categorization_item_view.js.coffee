@Docyt.module "AdvisorHomeApp.Shared", (Shared, App, Backbone, Marionette, $, _) ->

  class Shared.FileCategorizationItemView extends Marionette.ItemView
    template: 'advisor_home/clients/shared/file_categorization_item_view_tmpl'

    ui:
      progressBarWrapper: '.upload-file-status'
      autocompleteSelect: '.file-category'
      fileStatusIcon:     '.upload-file-status'
      fileTypeIcon:       '#file-icon'

    initialize: ->
      Docyt.vent.on('categories:loaded', @setAutocompleteOptions)
      Docyt.vent.on('categories:create:new', @addAutocompleteOption)

    onDestroy: ->
      Docyt.vent.off('categories:loaded')
      Docyt.vent.off('categories:create:new')

    onRender: ->
      @setFileIcon()
      @initAutocomplete()

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
          if value == ''
            @ui.fileStatusIcon.removeClass('upload-done')
            @model.unset('is_user_created_category')
          else
            @ui.fileStatusIcon.addClass('upload-done')
      )

    setFileIcon: ->
      @ui.fileTypeIcon.addClass(@model.getIconType())

    createNewCategory: (categoryName) =>
      newCategory =
        'id':   "#{_.uniqueId()}-userCreated"
        'name': categoryName

      @model.set('is_user_created_category', true)
      @model.set('category_name', newCategory['name'])

      Docyt.vent.trigger('categories:create:new', newCategory)
      newCategory

    setAutocompleteOptions: (categories) =>
      categoriesJSON = categories.toJSON()
      @selectizeSelect[0].selectize.addOption(categoriesJSON)

    addAutocompleteOption: (category) =>
      @selectizeSelect[0].selectize.addOption(category)
