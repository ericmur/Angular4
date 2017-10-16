@Docyt.module "AdvisorHomeApp.Contacts.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ContactsHeader extends Marionette.ItemView
    className: 'clients__search'
    template:  'advisor_home/contacts/index/contacts_index_header_tmpl'

    ui:
      addContact: '.add-contact-js'

    events:
      'click @ui.addContact': 'createContactModal'

    createContactModal: ->
      modalView = new Docyt.AdvisorHomeApp.Clients.Index.CreateClientModal
        model: new Docyt.Entities.Contact(type: 'Contact')

      Docyt.modalRegion.show(modalView)
