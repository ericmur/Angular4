@Docyt.module "Services", (Services, App, Backbone, Marionette, $, _) ->

  class Services.FayeClientBuilder extends Marionette.Object
    get_client: ->
      client = new Faye.Client(configData.fayeHost, {timeout: 120})
      client.addExtension(@getUserDataExtension())
      client

    # Interceptor, that sets user credentials for every outgoing message
    getUserDataExtension: ->
      UserDataExtension =
        incoming: (message, callback) ->
          callback(message)

        outgoing: (message, callback) ->
          message.data = {} unless message.data

          message.data.sender_type = 'User'
          message.data.sender_id   = Docyt.currentAdvisor.get('id')
          message.data.auth_token  = localStorage['auth_token']
          callback(message)
