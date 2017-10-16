@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.RightSideMenuLayout extends Marionette.LayoutView
    template:  'advisor_home/clients/show/documents/show/client_document_right_side_view_tmpl'
    className: 'document-right-side-region'

    regions:
      documentFieldsRegion: '#client-document-fields-region'
      documentOwnersRegion: '#client-document-owners-region'
