@Docyt.module "AdvisorHomeApp.Messaging.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.MessagingSideMenuItem extends Marionette.ItemView
    template: 'advisor_home/messaging/show/side_menu/messaging_side_menu_item_tmpl'

    ui:
      clientItem: '.client-item-js'

    initialize: ->
      Docyt.vent.on('update:messages:count', @setLastUnreadMessageTime)

    onDestroy: ->
      Docyt.vent.off('update:messages:count')

    onRender: ->
      @setupActiveClientStyle()
      @addLastUnreadMessageTime()

    templateHelpers: ->
      participantNames: @model.get('chat_title')

    setupActiveClientStyle: ->
      @ui.clientItem.addClass('active-chat') if @model.id == parseInt(@options.currentChatId)

    addLastUnreadMessageTime: ->
      return unless @model.get('unread_messages_count') > 0

      @setClientItemText(@model.get('last_message_created_at'))

    setLastUnreadMessageTime: (data) =>
      @setClientItemText(data['created_at']) if @model.get('id') == data['chat_id']

    setClientItemText: (createdAt) ->
      timeAgo = moment(createdAt).fromNow()
      @ui.clientItem.text("#{@model.get('chat_title')} (#{timeAgo})")
      @ui.clientItem.toggleClass('unread')
