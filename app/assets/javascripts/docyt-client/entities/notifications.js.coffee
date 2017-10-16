@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Notifications extends Backbone.Collection
    model: Docyt.Entities.Notification
    url: -> "/api/web/v1/advisor/notifications"

    parse: (response) ->
      Docyt.currentAdvisor.set('has_unread_notifications', false)
      response.notifications
