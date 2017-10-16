@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Layout extends Marionette.LayoutView
    className: 'client__wrap'
    template:  'advisor_home/clients/show/documents/show/documents_show_layout_tmpl'

    regions:
      detailsRegion:   '#client-details-region'
      sideMenuRegion:  '#client-side-menu-region'
      rightSideRegion: '#client-document-right-side-region'
