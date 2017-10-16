@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.UnconnectedClientModal extends Marionette.ItemView
    template: @getTemplate

    ui:
      closeCross: '#close'
      cancel:     '#cancel'

      sendSmsButton:   '#sms'
      sendEmailButton: '#email'

    events:
      'click @ui.closeCross': 'closeModal'
      'click @ui.cancel':     'closeModal'

      'click @ui.sendSmsButton':   'sendSms'
      'click @ui.sendEmailButton': 'sendEmail'

    onShow: ->
      @disableEmailButton() unless @model.get('email')
      @disableSmsButton()   unless @model.get('phone_normalized')

    getTemplate: ->
      if @model.get('email') || @model.get('phone_normalized')
        'advisor_home/clients/show/messages/clients_messages_unconnected_modal_tmpl'
      else
        'advisor_home/clients/show/messages/clients_messages_unconnected_modal_no_contacts_tmpl'

    closeModal: ->
      @destroy()

    disableEmailButton: ->
      @ui.sendEmailButton.addClass('disabled')

    disableSmsButton: ->
      @ui.sendSmsButton.addClass('disabled')

    sendSms: ->
      return unless @model.get('phone_normalized')
      message = @buildAndSendMessage('sms')

    sendEmail: ->
      return unless @model.get('email')
      message = @buildAndSendMessage('email')

    buildAndSendMessage: (messageType) ->
      message = new Docyt.Entities.Message
        text:       @options.text
        chatId:     @options.chatId
        receiverId: @model.get('id')
        receiverType: 'Client'

      message.send(messageType)
      Docyt.vent.trigger('chat:message:sent')
      @destroy()
