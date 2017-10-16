@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ParticipantsModal extends Marionette.CompositeView
    childViewContainer: 'table'
    childView: Index.ParticipantItemView
    template: 'advisor_home/workflows/index/workflows_participants_modal_tmpl'

    ui:
      cancel: '.cancel'

    events:
      'click @ui.cancel': 'closeModal'

    templateHelpers: ->
      workflowName: @options.workflow.get('name')

    closeModal: ->
      @destroy()
