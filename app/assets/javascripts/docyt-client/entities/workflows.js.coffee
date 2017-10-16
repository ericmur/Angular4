@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Workflows extends Backbone.Collection
    model: Docyt.Entities.Workflow
    url: -> "/api/web/v1/workflows"

    parse: (response) ->
      response.workflows
