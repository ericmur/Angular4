@Docyt.module "AdvisorHomeApp.Workflows.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.ParticipantsCollectionView extends Marionette.CompositeView
    template: 'advisor_home/workflows/show/details/participants/workflows_show_participants_collection_tmpl'
    childViewContainer: '.participants-container'

    getChildView: ->
      Show.ParticipantsItemView
