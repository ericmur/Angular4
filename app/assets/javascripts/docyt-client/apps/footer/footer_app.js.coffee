@Docyt.module "FooterApp", (FooterApp, App, Backbone, Marionette, $, _) ->
  @startWithParent = false

  FooterApp.on "start", ->
    controller = new FooterApp.Show.Controller
    controller.showFooter()
