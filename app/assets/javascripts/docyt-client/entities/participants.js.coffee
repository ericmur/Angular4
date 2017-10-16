@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Participants extends Backbone.Collection
    model: Docyt.Entities.Participant
