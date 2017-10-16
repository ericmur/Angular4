@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.ActionsBar extends Marionette.ItemView
    template:  'advisor_home/clients/show/messages/clients_messages_actions_bar_tmpl'
    className: 'client__mes-added-input-wrap'

    ui:
      inputFile:         '.input-file'
      contextMenu:       '.added-context-menu'
      messageInput:      '#message-input'
      sendMessageButton: '#send-message'

    events:
      'change @ui.inputFile':        'uploadFiles'
      'keydown @ui.messageInput':    'checkForEnter'
      'mouseleave @ui.contextMenu':  'hideMenuBar'
      'click @ui.sendMessageButton': 'showMenuBar'

    initialize: ->
      Docyt.vent.on('chat:message:sent', @clearInput)
      @client = @options.client

    onDestroy: ->
      Docyt.vent.off('chat:message:sent')

    onRender: ->
      @disableChatActions() if @client && !@client.isConnected()

    onShow: ->
      @ui.messageInput.focus()

    checkForEnter: (e) ->
      if e.keyCode == 13 && _.any([e.ctrlKey, e.altKey, e.shiftKey])
        e.preventDefault()
        @addNewLine()
      else
        @sendMessage(e) if e.keyCode == 13

    sendMessage: (e) ->
      e.preventDefault()

      return unless $.trim(@ui.messageInput.val())

      if @isConnectedClient() || @haveChatMembers()
        message = new Docyt.Entities.Message
          text:       @ui.messageInput.val()
          chatId:     @options.chatId
          senderName: Docyt.currentAdvisor.getName()
          receiverType: 'Client'

        message.send('web')
        @clearInput()

      else
        modalView = new Messages.UnconnectedClientModal
          model:  @client
          chatId: @options.chatId
          text:   @ui.messageInput.val()

        Docyt.modalRegion.show(modalView)
        modalView.triggerMethod('show')

    uploadFiles: (event) ->
      files = event.currentTarget.files
      if files.length && (@isConnectedClient() || @haveChatMembers())
        Docyt.vent.trigger('upload:file:from:action:bar', files)

    showMenuBar: ->
      if @ui.contextMenu.is(':hidden')
        @ui.contextMenu.show()
      else
        @ui.contextMenu.hide()

    hideMenuBar: ->
      @ui.contextMenu.hide()

    clearInput: =>
      @ui.messageInput.val('')
      @ui.messageInput.focus()

    disableChatActions: ->
      @ui.messageInput.attr('disabled', '')
      @ui.sendMessageButton.attr('disabled', '')

    addNewLine: ->
      @ui.messageInput.val(@ui.messageInput.val() + '\n')
      @ui.messageInput.scrollTop(@ui.messageInput[0].scrollHeight)

    haveChatMembers: ->
      @options.chatMembers && @options.chatMembers.length

    isConnectedClient: ->
      @client && @client.isConnected()
