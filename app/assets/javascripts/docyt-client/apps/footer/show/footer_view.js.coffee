@Docyt.module "FooterApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Footer extends Marionette.ItemView
    template:  'footer/show/footer_tmpl'
    className: 'footer'
