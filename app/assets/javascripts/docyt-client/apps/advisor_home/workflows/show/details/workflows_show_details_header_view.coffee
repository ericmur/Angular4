@Docyt.module "AdvisorHomeApp.Workflows.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.DetailsHeaderView extends Marionette.ItemView
    template: 'advisor_home/workflows/show/details/workflows_details_header_tmpl'

    templateHelpers: ->
      workflowName: @model.get('name')
