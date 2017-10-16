@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentOwners.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentOwnersList extends Marionette.CompositeView
    template: 'advisor_home/clients/show/documents/show/document_owners/document_owners_list_tmpl'
    childViewContainer: ".document-owners-list"

    getChildView: ->
      Index.DocumentOwnerItemView
