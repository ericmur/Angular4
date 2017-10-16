@Docyt.module "AdvisorHomeApp.LatestDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'latest_documents': 'showLatestDocuments'
