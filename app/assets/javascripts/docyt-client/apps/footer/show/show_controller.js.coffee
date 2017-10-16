@Docyt.module "FooterApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Marionette.Object

    showFooter: ->
      App.footerRegion.show(@getFooterView())

    getFooterView: ->
      new Show.Footer()
