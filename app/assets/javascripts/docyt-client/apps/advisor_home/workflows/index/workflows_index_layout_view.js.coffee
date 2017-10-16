@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Layout extends Marionette.LayoutView
    className: 'workflows__wrap'
    template:  'advisor_home/workflows/index/workflows_index_layout_tmpl'

    regions:
      headerMenuRegion:    '#workflows-header-menu-region'
      headerSortRegion:    '#workflows-sort-menu-region'
      workflowsListRegion: '#workflows-list-region'

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
