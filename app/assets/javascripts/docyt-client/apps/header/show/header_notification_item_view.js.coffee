@Docyt.module "HeaderApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.NotificationView extends Marionette.ItemView
    template:  'header/show/header_notification_view_tmpl'

    ui:
      notificationItem:     '.header__notifications-item'
      notificationDropDown: '#notifications-dropdown'

    events:
      'click @ui.notificationItem': 'hideNotifications'

    hideNotifications: ->
      @ui.notificationItem.parents('#notifications-dropdown').removeClass('active-dropdown')
