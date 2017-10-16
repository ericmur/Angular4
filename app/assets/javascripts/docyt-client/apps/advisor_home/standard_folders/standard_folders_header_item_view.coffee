@Docyt.module "AdvisorHomeApp.StandardFolders.HeaderMenu.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.HeaderItemView extends Marionette.ItemView
    template: @getTemplate

    ui:
      toggleCategoriesView: '.toggle-categoires-view-js'

    events:
      'click @ui.toggleCategoriesView': 'changeCategoriesView'

    initialize: ->
      @client   = @options.client
      @business = @options.business

    templateHelpers: ->
      titleDocuments: @getTitleDocuments()

    getTemplate: ->
      if @options.sideMenu
        'advisor_home/standard_folders/details/standard_folders_details_header_tmpl'
      else
        'advisor_home/standard_folders/standard_folders_header_tmpl'

    changeCategoriesView: ->
      if @client
        @checkClient()
      else if @business
        Docyt.vent.trigger('business:documents:change:categories:view', @business)
      else
        Docyt.vent.trigger('mydocuments:change:categories:view')

    onRender: ->
      @setHighlightTab()

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')

      elem = if @business then $("#business_#{@business.get('id')}") else $('#my_documents_tab')
      elem.addClass('header__nav-item--active')

    checkClient: ->
      if @client.get('type') == 'Client'
        Docyt.vent.trigger('client:change:categories:view')
      else
        Docyt.vent.trigger('contact:change:categories:view')

    getTitleDocuments: ->
      if @business then @business.get('name') else 'My Documents'
