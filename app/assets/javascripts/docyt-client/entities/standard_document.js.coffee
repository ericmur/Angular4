@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.StandardDocument extends Backbone.Model
    urlRoot: -> "/api/web/v1/standard_document"

    parse: (response) ->
      if response.standard_document then response.standard_document else response
