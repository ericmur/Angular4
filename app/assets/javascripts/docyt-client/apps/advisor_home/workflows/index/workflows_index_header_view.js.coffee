@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.WorkflowsHeader extends Marionette.ItemView
    className: 'workflows__search'
    template:  'advisor_home/workflows/index/workflows_index_header_tmpl'

    ui:
      addWorkflowButton: '#add-workflow'

    events:
      'click @ui.addWorkflowButton': 'openCreateWorkflowModal'

    openCreateWorkflowModal: ->
      modalView = new Index.SelectWorkflowTypeModal
        model: new Docyt.Entities.Workflow(elements: [])

      Docyt.modalRegion.show(modalView)
