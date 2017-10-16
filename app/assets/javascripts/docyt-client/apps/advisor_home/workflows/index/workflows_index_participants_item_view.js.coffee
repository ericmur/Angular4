@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ParticipantItemView extends Marionette.ItemView
    template: 'advisor_home/workflows/index/workflows_participants_tmpl'
    tagName: 'tr'
    className: 'client__docs-cell document-field-row'
