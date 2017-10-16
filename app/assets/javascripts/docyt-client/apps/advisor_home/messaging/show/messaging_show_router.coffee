@Docyt.module "AdvisorHomeApp.Messaging.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'messaging':          'showMessaging'
      'messaging/:chat_id': 'showChat'

      'messaging/:chat_id/messages/:id/document': 'showChatDocument'

