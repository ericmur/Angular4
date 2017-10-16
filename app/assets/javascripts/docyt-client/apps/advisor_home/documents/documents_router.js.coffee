@Docyt.module "AdvisorHomeApp.Documents", (Documents, App, Backbone, Marionette, $, _) ->

  class Documents.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'document/:id': 'showDocument'
