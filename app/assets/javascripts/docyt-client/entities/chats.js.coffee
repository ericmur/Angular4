@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Chats extends Backbone.Collection
    model: Docyt.Entities.Chat
    url: -> "/api/web/v1/chats"

    parse: (response) ->
      response.chats
