@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.ChatMessageItemView extends Marionette.CompositeView
    className: 'client__mes-card-wrap'
    tagName:   'div'
    template:  'advisor_home/clients/show/messages/clients_messages_item_tmpl'

    ui:
      contextMenu:   '.context-menu'
      messageItem:   '.message-item'
      editMessage:   '.edit-message'
      triangleItem:  '.triangle-item'
      markAsUnread:  '.mark-unread-message'
      deleteMessage: '.delete-message'

      messageText:         '.client__mes-content-text'
      editMessageForm:     '.edit-message-form'
      editMessageInput:    '.edit-message-input'
      cancelEditMessage:   '.cancel-edit-message'
      submitUpdateMessage: '.submit-update-message'

    events:
      'click @ui.editMessage':      'showEditMessageForm'
      'click @ui.triangleItem':     'showMenuBar'
      'click @ui.markAsUnread':     'markAsUnread'
      'click @ui.deleteMessage':    'deleteMessage'
      'mouseleave @ui.contextMenu': 'hideMenuBar'

      'click @ui.cancelEditMessage':   'hideEditMesageForm'
      'click @ui.submitUpdateMessage': 'updateMessage'

    templateHelpers: ->
      avatarUrl: @model.getSenderAvatarUrl()
      timestamp: moment(@model.get('created_at')).format("ddd, MMM D YYYY, h:mm A")

    showMenuBar: ->
      if @ui.contextMenu.is(':hidden')
        @ui.contextMenu.show()
      else
        @ui.contextMenu.hide()

    hideMenuBar: ->
      @ui.contextMenu.hide()

    deleteMessage: ->
      @model.destroy()

    updateMessage: ->
      text = $.trim(@ui.editMessageInput.val())

      return unless text

      @model.set('text', text)
      @model.update()
      @hideEditMesageForm()

    showEditMessageForm: ->
      @ui.messageText.hide()
      @ui.editMessageForm.show()
      @ui.editMessageInput.focus()
      @hideMenuBar()

    hideEditMesageForm: ->
      @ui.editMessageForm.hide()
      @ui.messageText.show()

    markAsUnread: ->
      @ui.contextMenu.hide()
      @model.markAsUnread()
