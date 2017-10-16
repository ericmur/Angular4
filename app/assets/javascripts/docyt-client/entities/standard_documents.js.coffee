@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.StandardDocuments extends Backbone.Collection
    model: Docyt.Entities.StandardDocument
    url: -> "/api/web/v1/standard_documents"

    parse: (response) ->
      response.standard_documents
