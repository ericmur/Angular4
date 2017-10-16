@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.StandardFolders extends Backbone.Collection
    model: Docyt.Entities.StandardFolder
    comparator: 'rank'
    url: -> 'api/web/v1/standard_folders'

    parse: (response) ->
      response.standard_folders
