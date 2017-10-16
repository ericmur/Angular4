@Docyt.module "AdvisorHomeApp.Clients.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.DocumentTypesCollectionModal extends Marionette.CompositeView
    template: 'advisor_home/clients/show/details/document_types_modal/document_types_collection_modal_tmpl'
    childViewContainer: 'table'

    getChildView: ->
      Details.DocumentTypesItemModal

    ui:
      cancel: '.cancel'

    events:
      'click @ui.cancel': 'closeModal'

    templateHelpers: ->
      clientName: @options.client.get('parsed_fullname')

    closeModal: ->
      @destroy()
