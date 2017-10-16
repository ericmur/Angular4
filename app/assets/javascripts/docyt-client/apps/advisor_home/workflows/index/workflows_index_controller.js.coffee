@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Marionette.Object

    showWorkflows: ->
      workflowsCollection   = @getWorkflows()
      workflowsHeaderView   = @getWorkflowsHeader()
      workflowsLayoutView   = @getWorkflowsIndexLayout()
      workflowsSortMenuView = @getWorkflowsSortMenu()

      App.mainRegion.show(workflowsLayoutView)

      workflowsLayoutView.headerMenuRegion.show(workflowsHeaderView)
      workflowsLayoutView.headerSortRegion.show(workflowsSortMenuView)

      workflowsCollection.fetch().done () =>
        workflowsLayoutView.workflowsListRegion.show(@getWorkflowsListView(workflowsCollection))

    getWorkflowsListView: (workflowsCollection) ->
      new Index.WorkflowsList({ collection: workflowsCollection })

    getWorkflows: ->
      new App.Entities.Workflows()

    getWorkflowsHeader: ->
      new Index.WorkflowsHeader()

    getWorkflowsIndexLayout: ->
      new Index.Layout()

    getWorkflowsSortMenu: ->
      new Index.SortMenu()
