@Docyt.module "HeaderApp", (HeaderApp, App, Backbone, Marionette, $, _) ->
  @startWithParent = false

  HeaderApp.on "start", ->
    controller = new HeaderApp.Show.Controller
    controller.showHeader()
