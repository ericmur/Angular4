@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Businesses extends Backbone.Collection
    model: Docyt.Entities.Business
    url: -> "/api/web/v1/businesses"

    parse: (response) ->
      response.businesses
