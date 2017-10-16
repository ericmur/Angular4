@Docyt.module "AdvisorHomeApp.Workflows.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.WorkflowSideMenuCollection extends Marionette.CompositeView
    template: 'advisor_home/workflows/show/side_menu/workflows_side_menu_collection_tmpl'
    childViewContainer: '.workflows-list'

    getChildView: ->
      Show.WorkflowSideMenuItem

    childViewOptions: ->
      currentWorkflowId: @options.currentWorkflowId

    ui:
      addWorkflowButton: '.create-workflow-js'

    events:
      'click @ui.addWorkflowButton': 'openCreateWorkflowModal'

    initialize: ->
      Docyt.vent.on('workflow:created', @addWorkflow)

    onDestroy: ->
      Docyt.vent.off('workflow:created')

    openCreateWorkflowModal: ->
      modalView = new Docyt.AdvisorHomeApp.Workflows.Index.SelectWorkflowTypeModal
        model: new Docyt.Entities.Workflow(elements: [])

      Docyt.modalRegion.show(modalView)

    addWorkflow: (response) =>
      workflow = new Docyt.Entities.Workflow(response.workflow)
      @collection.add(workflow)
