@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Files extends Backbone.Collection
    model: Docyt.Entities.File
    url: -> "/api/web/v1/documents"
