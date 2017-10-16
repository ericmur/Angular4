@Docyt.module "AdvisorHomeApp.StandardFolders.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'my_documents': 'showStandardFolders'
      'my_documents/:category_id': 'showCategoryDocuments'
      'my_documents/:category_id/documents/:id': 'showCategoryDocument'
