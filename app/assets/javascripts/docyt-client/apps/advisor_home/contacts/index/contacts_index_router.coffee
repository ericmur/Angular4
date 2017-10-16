@Docyt.module "AdvisorHomeApp.Contacts.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Marionette.AppRouter
    appRoutes:
      'contacts': 'showContacts'
