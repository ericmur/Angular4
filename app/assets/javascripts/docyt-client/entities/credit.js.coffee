@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.CreditCard extends Backbone.Model
    urlRoot: -> "/api/web/v1/credits"
    paramRoot: 'credit'

    parse: (response) ->
      if response.credit then response.credit else response

