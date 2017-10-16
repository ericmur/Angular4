@Docyt.module "AdvisorHomeApp.Profile", (Profile, App, Backbone, Marionette, $, _) ->

  class Profile.Router extends Marionette.AppRouter
    appRoutes:
      'profile': 'showAdvisorProfilePage'
