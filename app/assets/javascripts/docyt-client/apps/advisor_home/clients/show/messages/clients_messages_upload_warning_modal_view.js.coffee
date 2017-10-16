@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.UploadWarningModal extends Marionette.ItemView
    template: 'advisor_home/clients/show/messages/clients_messages_upload_warning_modal_tmpl'

    ui:
      closeModal:     '#close'
      cancelUpload:   '#cancel-upload'
      continueUpload: '#continue-upload'

    events:
      'click @ui.closeModal':     'leavePage'
      'click @ui.cancelUpload':   'leavePage'
      'click @ui.continueUpload': 'continueUpload'

    leavePage: ->
      @destroy()
      window.onbeforeunload = null
      Backbone.history.navigate(@options.link, { trigger: true })

    continueUpload: ->
      @destroy()
