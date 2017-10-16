@Docyt.module "AdvisorHomeApp.Workflows.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.WorkflowSideMenuItem extends Marionette.ItemView
    template: 'advisor_home/workflows/show/side_menu/workflows_side_menu_item_tmpl'

    ui:
      workflowElem: '.workflow__nav-item'

    onRender: ->
      @setupPastWorkflowColor()
      @setupActiveWorkflowColor()

    setupPastWorkflowColor: ->
      @ui.workflowElem.addClass('disabled-item') if @isPastWorkflow()

    setupActiveWorkflowColor: ->
      @ui.workflowElem.addClass('active-workflow') if @model.id == parseInt(@options.currentWorkflowId)

    isPastWorkflow: ->
      @model.setDeadline()
      @model.has('ago') || @model.has('today')
