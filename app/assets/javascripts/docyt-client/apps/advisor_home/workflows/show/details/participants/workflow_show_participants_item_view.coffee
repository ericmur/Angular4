@Docyt.module "AdvisorHomeApp.Workflows.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.ParticipantsItemView extends Marionette.ItemView
    template:  'advisor_home/workflows/show/details/participants/workflows_show_participants_item_tmpl'
    className: 'workflow-participant-progress'

    templateHelpers: ->
      avatarUrl:       @model.getAvatarUrl()
      participantName: @model.get('full_name')
