@Docyt.module "AdvisorHomeApp.LatestDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Layout extends Marionette.LayoutView
    className: 'latest-documents__wrap'
    template:  'advisor_home/latest_documents/index/latest_documents_index_layout_tmpl'

    regions:
      documentsRegion: '#latest-documents-region'

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
      $('#latest_documents_tab').addClass('header__nav-item--active')

    showSpinner: ->
      $('body').addClass('spinner-open')
      $('body').append("<div class='spinner-overlay'><i class='fa fa-spinner fa-pulse'></i></div>")

    hideSpinner: ->
      $('body').removeClass('spinner-open')
      $('.spinner-overlay').remove()
