@Docyt.module "AdvisorHomeApp.ReviewDocuments.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'review_documents/:id': 'showDocument'
