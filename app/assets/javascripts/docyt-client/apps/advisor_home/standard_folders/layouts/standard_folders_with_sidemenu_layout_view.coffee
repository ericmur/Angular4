@Docyt.module "AdvisorHomeApp.StandardFolders.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.WithSideMenuLayout extends Marionette.LayoutView
    className: 'categories__wrap'
    template:  'advisor_home/standard_folders/layouts/standard_folders_with_sidemenu_layout_tmpl'

    regions:
      sideMenuRegion:        '#categories-side-menu-region'
      categoryDetailsRegion: '#category-details-region'
      rightSideRegion:       '#category-right-side-region'

    onRender: ->
      $('body').addClass('two-column')

    onDestroy: ->
      $('body').removeClass('two-column')
