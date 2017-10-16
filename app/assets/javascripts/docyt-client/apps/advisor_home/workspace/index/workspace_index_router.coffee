@Docyt.module "AdvisorHomeApp.Workspace.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'select_workspace': 'showWorkspaces'
