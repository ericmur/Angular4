@Docyt.module "AdvisorHomeApp.Contacts.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.Router extends Marionette.AppRouter
    appRoutes:
      'contacts/:id/details': 'showContactDetails'
