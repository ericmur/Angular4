@Docyt.module "Services", (Services, App, Backbone, Marionette, $, _) ->

  class Services.FilesCollectionBuilder extends Marionette.Object
    initialize: (files) ->
      @files = files
      @filesCollection = new Docyt.Entities.Files

    populate: ->
      for file in @files
        fileModel = new Docyt.Entities.File
          original_file_name: file.name
          storage_size: file.size

        fileModel.set('file_content_type', file.type) if file.type

        @filesCollection.push(fileModel)

      @filesCollection
