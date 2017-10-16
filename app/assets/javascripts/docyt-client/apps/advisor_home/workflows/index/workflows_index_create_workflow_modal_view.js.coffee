@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.CreateWorkflowModal extends Marionette.ItemView
    template: 'advisor_home/workflows/index/workflows_index_create_workflow_modal_tmpl'

    ui:
      cancel: '.cancel'

    events:
      'click @ui.cancel': 'closeModal'

    closeModal: ->
      @destroy()
