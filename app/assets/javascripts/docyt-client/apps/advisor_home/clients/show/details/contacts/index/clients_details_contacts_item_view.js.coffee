@Docyt.module "AdvisorHomeApp.Clients.Show.Details.Contacts.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ContactsItemView extends Marionette.ItemView
    template: 'advisor_home/clients/show/details/contacts/index/clients_details_contacts_item_tmpl'

    templateHelpers: ->
      avatarUrl: @model.getAvatarUrl()
      showDocumentsContactUrl: @getShowDocumentsContactUrl()

    getShowDocumentsContactUrl: ->
      if @options.client.get('type') == 'Client'
        clientType = 'clients'
      else
        clientType = 'contacts'

      "/#{clientType}/#{@options.client.get('id')}/details/documents/contacts/#{@model.get('id')}/#{@model.get('type')}"
