@Docyt.module "AdvisorHomeApp.Workflows.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.WorkflowLayout extends Marionette.LayoutView
    className: 'workflow__wrap'
    template:  'advisor_home/workflows/show/workflows_layout_tmpl'

    regions:
      sideMenuRegion:        '#workflow-side-menu-region'
      rightSideRegion:       '#workflow-document-right-side-region'
      workflowDetailsRegion: '#workflow-details-region'

    initialize: ->
      Docyt.vent.on('show:spinner', @showSpinner)
      Docyt.vent.on('hide:spinner', @hideSpinner)

    onDestroy: ->
      Docyt.vent.off('show:spinner')
      Docyt.vent.off('hide:spinner')

    onRender: ->
      @setHighlightTab()

    showSpinner: ->
      $('body').addClass('spinner-open')
      $('body').append("<div class='spinner-overlay'><i class='fa fa-spinner fa-pulse'></i></div>")

    hideSpinner: ->
      $('body').removeClass('spinner-open')
      $('.spinner-overlay').remove()

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('#workflows_tab').addClass('header__nav-item--active')
