@Docyt.module "AdvisorHomeApp.Shared", (Shared, App, Backbone, Marionette, $, _) ->

  class Shared.DocumentsUploadModalNoClientView extends Marionette.ItemView
    template: 'advisor_home/clients/shared/documents_upload_modal_no_client_tmpl'

    ui:
      closeCross:    '.close'
      cancelUpload:  '#cancel-upload'
      confirmUpload: '#confirm-upload'

      # custom select elements
      clientSelectMenu:     '#client-menu'
      clientSelectOptions:  '#select-options'
      clientSelectOption:   '.client-select__menu-item'
      clientSelectedOption: '#selected-option'

      # validation messages
      clientNotSelected:    '#client-not-selected'

    events:
      'click @ui.closeCross':    'closeModal'
      'click @ui.cancelUpload':  'closeModal'
      'click @ui.confirmUpload': 'uploadDocuments'

      # custom select events
      'click @ui.clientSelectMenu':   'showSelectOptions'
      'click @ui.clientSelectOption': 'setClient'

    templateHelpers: ->
      files:   @options.files
      clients: @options.clients

    showSelectOptions: (evt) ->
      evt.stopPropagation()
      @ui.clientSelectOptions.show()

    setClient: (evt) ->
      @ui.clientSelectedOption.text(evt.currentTarget.textContent)
      selectedClientId = evt.currentTarget.dataset.option
      @selectedClient = _.find(@options.clients, { id: parseInt(selectedClientId) })
      @ui.clientSelectOptions.hide()

    clientSelected: ->
      if @selectedClient
        @ui.clientNotSelected.hide()
        true
      else
        @ui.clientNotSelected.show()
        false

    closeModal: ->
      @destroy()

    uploadDocuments: ->
      return unless @clientSelected()

      filesCollection = new Docyt.Services.FilesCollectionBuilder(@options.files).populate()

      modalView = new Docyt.AdvisorHomeApp.Shared.FilesUploadProgressModal
        collection: filesCollection
        files:  @options.files
        client: @selectedClient

      Docyt.modalRegion.show(modalView)
      @destroy()
