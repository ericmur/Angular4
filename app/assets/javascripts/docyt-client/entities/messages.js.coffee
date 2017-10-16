@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Messages extends Backbone.Collection
    model: Docyt.Entities.Message
    url: -> "/api/web/v1/messages"

    subscribeToChat: (chatId) ->
      @unsubscribeFromChat() if @subscription # only one subscription should be active
      @subscription = Docyt.fayeClient.subscribe("/chats/#{chatId}", (data) =>
        if data.error
          console.warn("Error: #{data.error}")
        else
          newMessage = new Docyt.Entities.Message(data)
          @sendReadMessageToFaye(newMessage)
          Docyt.vent.trigger('chat:update', newMessage)
      )

    unsubscribeFromChat: ->
      @subscription.cancel()

    parse: (response) ->
      @chatInfo = response.chat_info
      response.messages

    sendReadMessageToFaye: (message) ->
      message.set('read', true)

      params =
        message: message.attributes

      Docyt.fayeClient.publish("/service/message_ack", params)

    getUniqDates: ->
      uniqDates = _.uniq(
        _.map(@models, (message) ->
          moment(message.get('created_at')).format('MMMM YYYY')
        )
      )

      _.map(uniqDates, (uniqDate) ->
        { date: uniqDate }
      )
