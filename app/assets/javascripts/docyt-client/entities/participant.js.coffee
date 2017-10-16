@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Participant extends Backbone.Model

    initialize: ->
      @setStandardDocumentsCollection()

    setStandardDocumentsCollection: ->
      @set('standard_documents', new Docyt.Entities.StandardDocuments(@get('standard_documents')))

    getAvatarUrl: ->
      return if !@has('avatar')

      s3_object_key = @get('avatar').s3_object_key
      "https://#{configData.bucketName}.s3.amazonaws.com/#{s3_object_key}"
