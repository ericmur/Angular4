@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentFieldsModal extends Marionette.CompositeView
    childViewContainer: 'table'
    childView: Index.DocumentFieldItemView
    template: 'advisor_home/clients/show/documents/index/clients_documents_fields_modal_tmpl'

    ui:
      cancel: '.cancel'

    events:
      'click @ui.cancel': 'closeModal'

    templateHelpers: ->
      categoryName: @options.categoryName

    childViewOptions: ->
      isDocumentFieldsModal: true

    closeModal: ->
      @destroy()
