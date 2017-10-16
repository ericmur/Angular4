@Docyt.module "AdvisorHomeApp.Clients.Show.Details.Contacts", (Contacts, App, Backbone, Marionette, $, _) ->

  class Contacts.Layout extends Marionette.LayoutView
    className: 'client__wrap'
    template:  'advisor_home/clients/show/details/contacts/clients_details_contacts_layout_tmpl'

    regions:
      headerContactsMenu: '#clients-detail-contacts-header'
      contactsList:       '#clients-detail-contacts-list'
