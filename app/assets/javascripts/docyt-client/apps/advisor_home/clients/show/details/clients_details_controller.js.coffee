@Docyt.module "AdvisorHomeApp.Clients.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.Controller extends Marionette.Object

    showClientDetails: (clientId) ->
      client = @getClient(clientId)
      client.fetch().done =>
        clientLayoutView = @getClientLayoutView()
        App.mainRegion.show(clientLayoutView)

        clientHeaderMenuView = @getClientHeaderMenuView(client)
        clientSideMenuView   = @getClientSideMenuView(client)
        clientDetailsView = @getClientDetailsView(client)

        clientLayoutView.headerMenuRegion.show(clientHeaderMenuView)
        clientLayoutView.sideMenuRegion.show(clientSideMenuView)
        clientLayoutView.detailsRegion.show(clientDetailsView)

        if client.hasContacts()
          activeTab = @getActiveTab(client)
          clientDetailsContactsLayoutView = @getClientDetailsContactsLayoutView()
          headerContacts = @getHeaderContactsMenu(client, activeTab)

          contactsRegion = clientLayoutView.detailsContactsRegion

          contactsRegion.show(clientDetailsContactsLayoutView)
          clientDetailsContactsLayoutView.headerContactsMenu.show(headerContacts)

          contacts = @getContacts()
          contacts.fetch(data: { group_label: activeTab, client_id: clientId }).done =>
            clientContactsListView = @getContactsListView(contacts, client)
            clientDetailsContactsLayoutView.contactsList.show(clientContactsListView)

    getClient: (clientId) ->
      new Docyt.Entities.Client
        id: clientId

    getContacts: ->
      new Docyt.Entities.Contacts()

    getClientLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Layout()

    getClientDetailsContactsLayoutView: ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.Contacts.Layout()

    getHeaderContactsMenu: (client, tab) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.Contacts.HeaderMenu({ model: client, activeSubmenu: tab })

    getListContacts: () ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.Contacts.Layout()

    getClientHeaderMenuView: (client) ->
      new Details.HeaderMenu({ model: client })

    getClientSideMenuView: (client) ->
      new Docyt.AdvisorHomeApp.Clients.Show.SideMenu
        model: client
        activeSubmenu: 'details'

    getClientDetailsView: (client) ->
      new Details.View({ model: client })

    getContactsListView: (groupUsersCollection, client) ->
      new Docyt.AdvisorHomeApp.Clients.Show.Details.Contacts.Index.ContactsList
        client: client
        collection: groupUsersCollection

    getActiveTab: (client) ->
      if client.get('employees_count') > 0
        'Employee'
      else if client.get('contractors_count') > 0
        'Contractor'
      else
        'Contacts' if client.get('contacts_count') > 0
