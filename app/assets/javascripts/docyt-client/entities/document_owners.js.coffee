@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.DocumentOwners extends Backbone.Collection
    model: Docyt.Entities.DocumentOwner
