@Docyt.module "AdvisorHomeApp.Statistics.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.DocumentTypeView extends Marionette.ItemView
    template: 'advisor_home/statistics/show/document_types/document_types_item_tmpl'
    className: 'document-type-li'

    ui:
      documentsCount: '.documents-count-js'

    events:
      'click @ui.documentsCount': 'documentUploadersModal'

    documentUploadersModal: (e) ->
      e.preventDefault()
      e.stopPropagation()

      @model.fetch().done =>
        @showDocumentUploadersModal()
      .error =>
        toastr.error('Cannot display info about this category. Try later.', 'Something went wrong.')

    showDocumentUploadersModal: ->
      modalView = new Show.DocumentUploadersCollectionModal
        collection:   new Docyt.Entities.DocumentUploaders(@model.get('document_uploaders'))
        categoryName: @model.get('name')

      Docyt.modalRegion.show(modalView)
