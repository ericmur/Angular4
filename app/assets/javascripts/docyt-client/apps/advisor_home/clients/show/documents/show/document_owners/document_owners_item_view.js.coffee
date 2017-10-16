@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentOwners.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentOwnerItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/documents/show/document_owners/document_owners_item_tmpl'

    templateHelpers: ->
      avatarUrl: @model.getOwnerAvatarUrl()
