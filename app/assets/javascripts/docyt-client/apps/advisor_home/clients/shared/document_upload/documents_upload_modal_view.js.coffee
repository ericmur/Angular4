@Docyt.module "AdvisorHomeApp.Shared", (Shared, App, Backbone, Marionette, $, _) ->

  class Shared.DocumentsUploadModalView extends Marionette.ItemView
    template: 'advisor_home/clients/shared/documents_upload_modal_tmpl'

    ui:
      closeCross:    '.close'
      cancelUpload:  '#cancel-upload'
      confirmUpload: '#confirm-upload'

    events:
      'click @ui.closeCross':    'closeModal'
      'click @ui.cancelUpload':  'closeModal'
      'click @ui.confirmUpload': 'uploadDocuments'

    initialize: ->
      @userObject = @options.contact || @options.client

    templateHelpers: ->
      files:      @options.files
      objectName: @getObjectName()

    closeModal: ->
      @destroy()

    getObjectName: ->
      return @userObject.get('parsed_fullname') if @userObject

      @options.business.get('name')

    uploadDocuments: ->
      modalView = new Docyt.AdvisorHomeApp.Shared.FilesUploadProgressModal
        files:      @options.files
        client:     @options.client
        contact:    @options.contact
        business:   @options.business
        collection: new Docyt.Services.FilesCollectionBuilder(@options.files).populate()

      Docyt.modalRegion.show(modalView)
      @destroy()
