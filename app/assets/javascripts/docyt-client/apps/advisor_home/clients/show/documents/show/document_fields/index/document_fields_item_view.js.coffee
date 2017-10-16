@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentFieldItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/documents/show/document_fields/document_fields_item_tmpl'
