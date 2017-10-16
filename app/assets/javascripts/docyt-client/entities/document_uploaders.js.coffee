@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.DocumentUploaders extends Backbone.Collection
    model: Docyt.Entities.DocumentUploader
