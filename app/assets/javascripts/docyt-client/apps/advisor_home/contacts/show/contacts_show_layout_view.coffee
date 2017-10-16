@Docyt.module "AdvisorHomeApp.Contacts.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Layout extends Marionette.LayoutView
    className: 'client__wrap'
    template:  'advisor_home/contacts/show/contacts_layout_tmpl'

    regions:
      detailsRegion:         '#contact-details-region'
      sideMenuRegion:        '#contact-side-menu-region'
      headerMenuRegion:      '#contact-header-menu-region'
      categoriesBoxesRegion: '#contact-categories-boxes-region'
      detailsContactsRegion: '#contact-details-contacts-region'

    onRender: ->
      @setHighlightTab()

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('#contacts_tab').addClass('header__nav-item--active')
