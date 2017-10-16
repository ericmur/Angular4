@Docyt.module "AdvisorHomeApp.StandardFolders.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.SideMenuItem extends Marionette.ItemView
    template: 'advisor_home/standard_folders/side_menu/standard_folders_side_menu_item_tmpl'

    ui:
      categoryItem: '.category-item-js'

    initialize: ->
      Docyt.vent.on('category:changed', @updateCounter)

    onDestroy: ->
      Docyt.vent.off('category:changed')

    templateHelpers: ->
      iconUrl:     @model.getIconS3Url()
      categoryUrl: @getCategoryUrl()

    onRender: ->
      @setupActiveCategoryStyle()

    setupActiveCategoryStyle: ->
      @ui.categoryItem.addClass('active-category') if @model.get('id') == parseInt(@options.currentCategoryId)

    getCategoryUrl: ->
      if @options.business
        "businesses/#{@options.business.get('id')}/standard_folders/#{@model.get('id')}"
      else
        "my_documents/#{@model.get('id')}"

    updateCounter: (standardFolderId) =>
      return unless standardFolderId == @model.get('id')

      @model.set('documents_count', @model.get('documents_count') + 1)
      @render()
