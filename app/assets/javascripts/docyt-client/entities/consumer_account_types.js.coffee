@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.ConsumerAccountTypes extends Backbone.Collection
    model: Docyt.Entities.ConsumerAccountType
    url: -> '/api/web/v1/consumer_account_types'

    parse: (response) ->
      response.consumer_account_types

    getType: (type) ->
      @findWhere(display_name: type)
