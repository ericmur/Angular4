@Docyt.module "AdvisorHomeApp.Clients.Show.Details.Contacts", (Contacts, App, Backbone, Marionette, $, _) ->

  class Contacts.HeaderMenu extends Marionette.ItemView
    template: 'advisor_home/clients/show/details/contacts/clients_details_contacts_header_menu_tmpl'

    ui:
      contactsNav: '#contacts-nav'
      employeesNav: '#employees-nav'
      contractorsNav: '#contractors-nav'

    templateHelpers: ->
      contractorsUrl: "/clients/#{@model.get('id')}/details/contacts/contractors"
      employeesUrl: "/clients/#{@model.get('id')}/details/contacts/employees"
      contactsUrl: "/clients/#{@model.get('id')}/details/contacts/contacts"
      contractorsCount: @model.get('contractors_count')
      employeesCount: @model.get('employees_count')
      contactsCount: @model.get('contacts_count')

    onRender: ->
      @highlightActiveNav()

    highlightActiveNav: ->
      switch @options.activeSubmenu
        when 'Contacts'
          @ui.contactsNav.addClass('active')
        when 'Employee'
          @ui.employeesNav.addClass('active')
        when 'Contractor'
          @ui.contractorsNav.addClass('active')
