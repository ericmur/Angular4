@Docyt.module "AdvisorHomeApp.Workflows.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'workflows/:id':'showWorkflow'
      'workflows/:id/messages/:id/document': 'showWorkflowDocument'
