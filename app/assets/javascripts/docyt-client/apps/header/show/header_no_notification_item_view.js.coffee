@Docyt.module "HeaderApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.NoNotificationView extends Marionette.ItemView
    template:  'header/show/header_no_notification_view_tmpl'