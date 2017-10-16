@Docyt.module "AdvisorHomeApp.Businesses.Show.StandardFolders.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'businesses/:id/standard_folders':     'showBusinessStandardFolders'
      'businesses/:id/standard_folders/:id': 'showBusinessCategoryDocuments'
      'businesses/:id/standard_folders/:id/documents/:id': 'showBusinessCategoryDocument'
