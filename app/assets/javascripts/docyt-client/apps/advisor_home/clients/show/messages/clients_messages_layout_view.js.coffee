@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.Layout extends Marionette.LayoutView
    template:  'advisor_home/clients/show/messages/clients_messages_layout_tmpl'

    regions:
      searchMessageRegion: '#messages-search-region'
      messagesRegion:      '#messages-region'
      actionsBarRegion:    '#actions-bar-region'

    initialize: ->
      Docyt.vent.on('warning:modal:when:uploading', @warningModal)

    onDestroy: ->
      Docyt.vent.off('warning:modal:when:uploading')

    onShow: ->
      $('body').find('#client-main-pane').addClass('client__mes')

    warningModal: (href) =>
      modalView = new Docyt.AdvisorHomeApp.Clients.Show.Messages.UploadWarningModal({ link: href })
      Docyt.modalRegion.show(modalView)
