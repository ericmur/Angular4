@Docyt.module "HeaderApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Marionette.Object

    showHeader: ->
      headerLayoutView = @getHeaderView()
      App.headerRegion.show(headerLayoutView)

    getHeaderView: ->
      new Show.Header()
