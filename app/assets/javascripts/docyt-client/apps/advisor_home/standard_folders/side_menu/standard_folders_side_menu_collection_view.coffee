@Docyt.module "AdvisorHomeApp.StandardFolders.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.SideMenuCollection extends Marionette.CompositeView
    template: 'advisor_home/standard_folders/side_menu/standard_folders_side_menu_collection_tmpl'
    childViewContainer: '.categories-list'
    className: 'categories-side-menu-wrap'

    getChildView: ->
      Show.SideMenuItem

    childViewOptions: ->
      business:          @options.business
      currentCategoryId: @options.currentCategoryId

    onRender: ->
      @setHighlightTab()

    onShow: ->
      @initCustomScrollbar()

    initCustomScrollbar: ->
      $('.categories-list').mCustomScrollbar(theme: 'minimal-dark', scrollInertia: 100)

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')

      elem = if @options.business then $("#business_#{@options.business.get('id')}") else $('#my_documents_tab')
      elem.addClass('header__nav-item--active')
