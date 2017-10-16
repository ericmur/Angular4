@Docyt.module "AdvisorHomeApp.Shared", (Shared, App, Backbone, Marionette, $, _) ->

  class Shared.FilesUploadProgressModal extends Marionette.CompositeView
    template:  'advisor_home/clients/shared/files_upload_progress_modal_tmpl'
    childViewContainer: '.upload-files-wrapper'

    getChildView: ->
      Shared.FileUploadItemView

    ui:
      closeCross:    '.close'
      cancelUpload:  '.cancel'
      uploadCounter: '#upload-counter'
      nextButton:    '#next'

    events:
      'click @ui.closeCross':    'closeModal'
      'click @ui.cancelUpload':  'closeModal'
      'click @ui.nextButton':    'showCategorizeStep'

    templateHelpers: ->
      files:      @options.files
      objectName: @getObjectName()
      uploadedFilesCount: @countUploadedFiles

    closeModal: ->
      @destroy()

    onRender: ->
      @disableNextButton()

    initialize: ->
      Docyt.vent.on('file:upload:success', @documentSaved)

      @business   = @options.business
      @userObject = @options.contact || @options.client

      @uploadedDocuments = new Docyt.Entities.Documents
      uploader = new Docyt.Services.UploadToS3Service(@setDataParams())
      uploader.upload()

    onDestroy: ->
      Docyt.vent.off('file:upload:success', @documentSaved)

    documentSaved: (documentHash) =>
      documentModel = new Docyt.Entities.Document(documentHash.documentJson)
      @uploadedDocuments.add(documentModel)
      @updateUploadedFilesCount()

    getObjectName: ->
      return @userObject.get('parsed_fullname') if @userObject

      @business.get('name')

    updateUploadedFilesCount: =>
      @ui.uploadCounter.text(@countUploadedFiles())
      @enableNextButton() if @uploadedDocuments.length == @options.files.length

    countUploadedFiles: =>
      I18n.t('file_upload.upload_counter',
        uploaded_count: @uploadedDocuments.length
        total_count:    @options.files.length
      )

    showCategorizeStep: ->
      return unless @nextStepAllowed

      modalView = new Docyt.AdvisorHomeApp.Shared.FilesCategorizationProgressModal
        client:     @userObject
        business:   @business
        collection: @uploadedDocuments

      Docyt.modalRegion.show(modalView)
      @destroy()

    disableNextButton: ->
      @nextStepAllowed = false
      @ui.nextButton.addClass('disabled')

    enableNextButton: ->
      @nextStepAllowed = true
      @ui.nextButton.removeClass('disabled')

    setDataParams: ->
      data =
        files:    @options.files
        client:   @options.client
        contact:  @options.contact
        business: @options.business
        filesCollection: @collection

      data
