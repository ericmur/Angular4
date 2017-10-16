@Docyt.module "AdvisorHomeApp.Contacts.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Marionette.Object

    DEFAULT_MEMBERS = ['Spouse', 'Dad', 'Mom', 'Kid']

    showContacts: ->
      contactsLayout = @getClientsLayoutView()

      App.mainRegion.show(contactsLayout)

      contacts = @getContacts()

      contacts.fetch(data: { user_id: Docyt.currentAdvisor.get('id') }).done =>
        contacts.add(@getDefaultsContacts()) if _.isEmpty(contacts.models)

        pagesCount = contacts.pagesCount

        contactsHeaderView = @getContactsHeaderView()
        contactsLayout.headerMenuRegion.show(contactsHeaderView)

        clientContactsListView = @getContactsListView(contacts, pagesCount)
        contactsLayout.clientsListRegion.show(clientContactsListView)

    getContacts: ->
      new Docyt.Entities.Contacts

    getContactsListView: (contacts, pagesCount) ->
      new Docyt.AdvisorHomeApp.Contacts.Index.ContactsList
        collection: contacts
        pagesCount: pagesCount

    getContactsHeaderView: ->
      new Docyt.AdvisorHomeApp.Contacts.Index.ContactsHeader

    getClientsLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Index.Layout

    getDefaultsContacts: ->
      _.map(DEFAULT_MEMBERS, (name) ->
        default: true
        parsed_fullname: name
      )
