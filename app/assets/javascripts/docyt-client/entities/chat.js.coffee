@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Chat extends Backbone.Model
    urlRoot: -> "/api/web/v1/chats"

    initialize: ->
      @setParticipantNames()

    parse: (response) ->
      if response.chat then response.chat else response

    setParticipantNames: ->
      result      = ''
      chatMembers = @get('chat_members')
      lastChatMember = _.last(chatMembers)

      _.each(chatMembers, (chatMember) ->
        full_name = chatMember.parsed_fullname

        return result += "#{full_name}, " unless lastChatMember.parsed_fullname == full_name

        result += full_name
      )

      @set('chat_title', result)

      result
