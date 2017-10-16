@Docyt.module "AdvisorHomeApp.Clients.Show.Details.Contacts.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Marionette.Object
    DEFAULT_SIDE_TAB = 'details'

    showClientContacts: (clientId, groupName) ->
      groupName = @getHumanizeGroupName(groupName)
      client = @getClient(clientId)
      client.fetch().done =>
        clientLayoutView = @getClientLayoutView()
        App.mainRegion.show(clientLayoutView)

        clientHeaderMenuView = @getClientHeaderMenuView(client)
        clientSideMenuView   = @getClientSideMenuView(client, DEFAULT_SIDE_TAB)

        clientDetailsContactsLayoutView = @getClientDetailsContactsLayoutView()
        headerContacts = @getHeaderContactsMenu(client, groupName)

        contactsRegion = clientLayoutView.detailsContactsRegion

        clientLayoutView.headerMenuRegion.show(clientHeaderMenuView)
        clientLayoutView.sideMenuRegion.show(clientSideMenuView)

        clientDetailsView = @getClientDetailsView(client)
        clientLayoutView.detailsRegion.show(clientDetailsView)

        contactsRegion.show(clientDetailsContactsLayoutView)
        clientDetailsContactsLayoutView.headerContactsMenu.show(headerContacts)

        contacts = @getContacts()
        contacts.fetch(data: { group_label: groupName, client_id: clientId }).done =>
          clientContactsListView = @getContactsListView(contacts, client)
          clientDetailsContactsLayoutView.contactsList.show(clientContactsListView)

    getClient: (clientId) ->
      new Docyt.Entities.Client
        id: clientId

    getContacts: ->
      new Docyt.Entities.Contacts()

    getHumanizeGroupName: (name) ->
      switch name
        when 'contractors'
          'Contractor'
        when 'employees'
          'Employee'
        else
          'Contacts'

    getClientDetailsView: (client) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.View({ model: client })

    getClientDetailsContactsLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.Contacts.Layout()

    getHeaderContactsMenu: (client, activeTab) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.Contacts.HeaderMenu({ model: client, activeSubmenu: activeTab })

    getClientHeaderMenuView: (client) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.HeaderMenu({ model: client })

    getClientLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Layout()

    getClientSideMenuView: (client, activeTab) ->
      new Docyt.AdvisorHomeApp.Clients.Show.SideMenu({ model: client, activeSubmenu: activeTab })

    getContactsListView: (contactsCollection, client) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.Contacts.Index.ContactsList
        client: client
        collection: contactsCollection
