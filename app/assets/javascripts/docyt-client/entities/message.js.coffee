@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Message extends Backbone.Model

    send: (type) ->
      params =
        text: @get('text')
        type: type

      Docyt.fayeClient.publish("/chats/#{@get('chatId')}", params)

    update: ->
      params =
        message:
          text:   @get('text')
          action: 'update'
          message_id: @get('id')

      Docyt.fayeClient.publish("/chats/#{@get('chat_id')}", params)

    destroy: ->
      params =
        message:
          action: 'delete'
          message_id: @get('id')

      Docyt.fayeClient.publish("/chats/#{@get('chat_id')}", params)

    getSenderAvatarUrl: ->
      return unless @has('sender_avatar')

      "https://#{configData.bucketName}.s3.amazonaws.com/#{@get('sender_avatar').s3_object_key}"

    markAsUnread: ->
      params =
        message:
          message_id: @get('id')

      Docyt.fayeClient.publish("/service/message_unread", params)
