@Docyt.module "AdvisorHomeApp.ReviewDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'review_documents': 'documentsForReviewIndex'
