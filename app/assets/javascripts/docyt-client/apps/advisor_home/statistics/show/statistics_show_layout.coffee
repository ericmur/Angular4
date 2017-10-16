@Docyt.module "AdvisorHomeApp.Statistics.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Layout extends Marionette.LayoutView
    className: 'statistics__wrap'
    template:  'advisor_home/statistics/show/statistics_layout_tmpl'

    regions:
      documentTypesRegion: '#document-types-region'

    initialize: ->
      Docyt.vent.on('show:spinner', @showSpinner)
      Docyt.vent.on('hide:spinner', @hideSpinner)

    onDestroy: ->
      Docyt.vent.off('show:spinner')
      Docyt.vent.off('hide:spinner')

    onRender: ->
      @setHighlightTab()

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('#statistics_tab').addClass('header__nav-item--active')

    showSpinner: ->
      $('body').addClass('spinner-open')
      $('body').append("<div class='spinner-overlay'><i class='fa fa-spinner fa-pulse'></i></div>")

    hideSpinner: ->
      $('body').removeClass('spinner-open')
      $('.spinner-overlay').remove()
