@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Avatar extends Backbone.Model
    url: -> "/api/web/v1/advisor/#{@get('advisor_id')}/avatar"
