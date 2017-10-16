@Docyt.module "AdvisorHomeApp.StandardFolders.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.BoxesLayout extends Marionette.LayoutView
    className: 'clients__wrap bg-white'
    template:  'advisor_home/standard_folders/layouts/standard_folders_boxes_layout_tmpl'

    regions:
      headerMenuRegion:        '#header-menu-region'
      categoriesBoxesRegion:   '#categories-boxes-region'
      documentsCategoryRegion: '#category-documents-region'
