@Docyt.module "AdvisorHomeApp.Contacts.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.Controller extends Marionette.Object

    showContactDetails: (contactId) ->
      contactLayoutView = @getContactDetailsLayoutView()
      App.mainRegion.show(contactLayoutView)

      contact = @getContact(contactId)
      contact.fetch().done =>
        sideMenuView = @getContactSideMenuView(contact)
        contactLayoutView.sideMenuRegion.show(sideMenuView)

        contactHeaderMenuView = @getContactHeaderMenuView(contact)
        contactLayoutView.headerMenuRegion.show(contactHeaderMenuView)

        contactDetailsView = @getContactDetailsView(contact)
        contactLayoutView.detailsRegion.show(contactDetailsView)

    getContact: (contactId) ->
      new App.Entities.Contact
        id: contactId

    getContactDetailsLayoutView: ->
      new App.AdvisorHomeApp.Contacts.Show.Layout

    getContactSideMenuView: (contact) ->
      new App.AdvisorHomeApp.Clients.Show.SideMenu
        model: contact
        activeSubmenu: 'details'

    getContactHeaderMenuView: (contact) ->
      new App.AdvisorHomeApp.Clients.Show.Details.HeaderMenu
        model: contact

    getContactDetailsView: (contact) ->
      new App.AdvisorHomeApp.Clients.Show.Details.View
        model: contact
