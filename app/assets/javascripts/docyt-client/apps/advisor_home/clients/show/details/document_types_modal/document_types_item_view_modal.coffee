@Docyt.module "AdvisorHomeApp.Clients.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.DocumentTypesItemModal extends Marionette.ItemView
    template: 'advisor_home/clients/show/details/document_types_modal/document_types_item_modal_tmpl'
    tagName: 'tr'
    className: 'client__docs-cell document-field-row'
