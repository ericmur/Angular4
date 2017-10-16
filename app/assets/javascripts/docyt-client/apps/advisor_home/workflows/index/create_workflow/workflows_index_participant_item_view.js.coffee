@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ParticipantModal extends Marionette.ItemView
    template:  'advisor_home/workflows/index/create_workflow/workflows_index_participant_item_view_modal_tmpl'

    ui:
      removeParticipant: '.remove-participant-js'

    events:
      'click @ui.removeParticipant': 'removeParticipant'

    templateHelpers: ->
      avatarUrl:       @model.getAvatarUrl()
      participantName: @model.get('parsed_fullname')

    removeParticipant: ->
      @model.collection.remove(@model)
