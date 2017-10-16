@Docyt.module "AdvisorHomeApp.Workflows.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.LayoutView extends Marionette.LayoutView
    template: 'advisor_home/workflows/show/details/workflows_details_layout_tmpl'

    regions:
      chatRegion:         '#workflow-details-chat-region'
      headerRegion:       '#workflow-details-header-region'
      participantsRegion: '#workflow-details-participants-region'
