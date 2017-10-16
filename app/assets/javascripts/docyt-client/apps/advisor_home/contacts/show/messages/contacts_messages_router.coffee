@Docyt.module "AdvisorHomeApp.Contacts.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'contacts/:id/messages':              'showContactMessages'
      'contacts/:id/messages/:id/document': 'showChatDocument'
