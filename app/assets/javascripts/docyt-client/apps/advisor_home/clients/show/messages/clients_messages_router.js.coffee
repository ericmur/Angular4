@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'clients/:id/messages':              'showClientMessages'
      'clients/:id/messages/:id/document': 'showChatDocument'
