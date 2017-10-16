@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.ChatMember extends Backbone.Model

    initialize: ->
      @set('avatarUrl', @getMemberAvatar())

    getMemberAvatar: ->
      return unless @has('avatar')

      "https://#{configData.bucketName}.s3.amazonaws.com/#{@get('avatar').s3_object_key}"
