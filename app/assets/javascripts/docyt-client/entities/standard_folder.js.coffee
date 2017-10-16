@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.StandardFolder extends Backbone.Model
    urlRoot: -> '/api/web/v1/standard_folders'

    parse: (response) ->
      if response.standard_folder then response.standard_folder else response

    getIconUrl: (size) ->
      @get("icon_name_#{size}")

    getIconS3Url: (size) ->
      @get("icon_url") #Ignoring size for now
