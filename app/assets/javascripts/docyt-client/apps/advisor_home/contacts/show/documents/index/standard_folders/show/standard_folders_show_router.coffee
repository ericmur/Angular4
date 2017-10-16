@Docyt.module "AdvisorHomeApp.Contacts.Show.Documents.Index.StandardFolders.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'contacts/:id/categories/:standard_folder_id/documents/:contact_id/:contact_type': 'showStandardFolderDocuments'
