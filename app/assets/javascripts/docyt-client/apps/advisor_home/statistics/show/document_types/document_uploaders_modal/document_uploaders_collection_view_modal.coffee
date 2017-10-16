@Docyt.module "AdvisorHomeApp.Statistics.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.DocumentUploadersCollectionModal extends Marionette.CompositeView
    template: 'advisor_home/statistics/show/document_types/document_uploaders/document_uploaders_collection_tmpl'
    childViewContainer: 'table'

    getChildView: ->
      Show.DocumentUploadersItemModal

    ui:
      cancel: '.cancel'

    events:
      'click @ui.cancel': 'closeModal'

    templateHelpers: ->
      categoryName: @options.categoryName

    closeModal: ->
      @destroy()


