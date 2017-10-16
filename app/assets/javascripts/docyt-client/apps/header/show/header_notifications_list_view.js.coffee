@Docyt.module "HeaderApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.NotificationsList extends Marionette.CompositeView
    className: 'header__notifications-content'
    template: 'header/show/header_notifications_list_tmpl'
    childView: Show.NotificationView
    emptyView: Show.NoNotificationView

    ui:
      spinner: '#notification-spinner'

    onShowSpinner: =>
      @ui.spinner.show()

    onHideSpinner: =>
      @ui.spinner.hide()
