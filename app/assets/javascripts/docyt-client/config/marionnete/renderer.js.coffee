Backbone.Marionette.Renderer.render = (template, data) ->
  path = JST["docyt-client/templates/" + template]
  unless path
    throw "Template #{template} not found!"
  path(data)
