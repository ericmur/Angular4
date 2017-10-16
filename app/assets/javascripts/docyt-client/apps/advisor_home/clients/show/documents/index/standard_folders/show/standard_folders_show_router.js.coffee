@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'clients/:id/categories/:standard_folder_id/documents/:contact_id/:contact_type': 'showStandardFolderDocuments'
