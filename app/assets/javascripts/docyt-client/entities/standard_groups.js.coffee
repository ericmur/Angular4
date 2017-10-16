@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.StandardGroups extends Backbone.Collection
    model: Docyt.Entities.StandardGroup
    url: -> '/api/web/v1/standard_groups'

    parse: (response) ->
      response.standard_groups

    getType: (type) ->
      @findWhere(name: type)
