@Docyt.module "AdvisorHomeApp.Documents", (Documents, App, Backbone, Marionette, $, _) ->

  class Documents.Layout extends Marionette.LayoutView
    className: 'client__wrap'
    template:  'advisor_home/documents/show/documents_show_layout_tmpl'

    regions:
      detailsRegion:   '#client-details-region'
      rightSideRegion: '#client-document-right-side-region'
