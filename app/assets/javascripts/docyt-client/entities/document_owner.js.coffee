@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.DocumentOwner extends Backbone.Model

    getOwnerAvatarUrl: ->
      if @get('owner_id') == Docyt.currentAdvisor.get('id')
        return unless Docyt.currentAdvisor.has('avatar')
        s3_object_key = Docyt.currentAdvisor.get('avatar').s3_object_key
      else
        return unless @has('owner_avatar')
        s3_object_key = @get('owner_avatar').s3_object_key
      "https://#{configData.bucketName}.s3.amazonaws.com/#{s3_object_key}"
