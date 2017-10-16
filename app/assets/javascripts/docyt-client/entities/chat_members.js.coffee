@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.ChatMembers extends Backbone.Collection
    model: Docyt.Entities.ChatMember
