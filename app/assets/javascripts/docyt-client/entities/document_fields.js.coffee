@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.DocumentFields extends Backbone.Collection
    model: Docyt.Entities.DocumentField

    parse: (response) ->
      if response.document_fields then response.document_fields else response
