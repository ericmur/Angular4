@Docyt.module "AdvisorHomeApp.Clients.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Layout extends Marionette.LayoutView
    className: 'client__wrap'
    template:  'advisor_home/clients/show/clients_layout_tmpl'

    regions:
      detailsRegion:         '#client-details-region'
      sideMenuRegion:        '#client-side-menu-region'
      rightSideRegion:       '#client-document-right-side-region'
      headerMenuRegion:      '#client-header-menu-region'
      categoriesBoxesRegion: '#client-categories-boxes-region'
      detailsContactsRegion: '#client-details-contacts-region'

    initialize: ->
      Docyt.vent.on('show:spinner', @showSpinner)
      Docyt.vent.on('hide:spinner', @hideSpinner)

    onDestroy: ->
      Docyt.vent.off('show:spinner')
      Docyt.vent.off('hide:spinner')

    showSpinner: ->
      $('body').addClass('spinner-open')
      $('body').append("<div class='spinner-overlay'><i class='fa fa-spinner fa-pulse'></i></div>")

    hideSpinner: ->
      $('body').removeClass('spinner-open')
      $('.spinner-overlay').remove()
