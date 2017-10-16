@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.WorkflowsList extends Marionette.CollectionView

    initialize: ->
      Docyt.vent.on('workflow:created', @addWorkflow)

    onDestroy: ->
      Docyt.vent.off('workflow:created')

    getChildView: ->
      Index.WorkflowView

    onRender: ->
      @setHighlightTab()

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('#workflows_tab').addClass('header__nav-item--active')

    addWorkflow: (response) =>
      workflow = new Docyt.Entities.Workflow(response.workflow)
      @collection.add(workflow)
