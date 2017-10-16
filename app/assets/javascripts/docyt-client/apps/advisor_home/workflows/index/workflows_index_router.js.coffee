@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'workflows' : 'showWorkflows'
