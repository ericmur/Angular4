@Docyt.module "AdvisorHomeApp.Statistics.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Router extends Docyt.Common.SecuredRouter
    appRoutes:
      'statistics': 'showStatistics'
