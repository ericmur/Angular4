@Docyt.module "AdvisorHomeApp.StandardFolders.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.Layout extends Marionette.LayoutView
    template:  'advisor_home/standard_folders/details/standard_folders_details_layout_tmpl'
    className: 'category-details-wrap'

    regions:
      headerMenuRegion: '#category-details-header-region'
      containerRegion:  '#category-details-container'
