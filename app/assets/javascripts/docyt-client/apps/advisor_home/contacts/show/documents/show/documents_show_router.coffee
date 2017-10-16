@Docyt.module "AdvisorHomeApp.Contacts.Show.Documents.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'contacts/:id/documents/:id': 'showDocument'
