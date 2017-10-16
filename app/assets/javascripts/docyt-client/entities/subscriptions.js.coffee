@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Subscriptions extends Backbone.Model
    urlRoot: -> "/api/web/v1/subscriptions"
    paramRoot: 'subscription'

    initialize: ->

    parse: (response) ->
      if response.subscription then response.subscription else response

