@Docyt.module "AdvisorHomeApp.Statistics.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.DocumentUploadersItemModal extends Marionette.ItemView
    template: 'advisor_home/statistics/show/document_types/document_uploaders/document_uploaders_item_tmpl'
    tagName: 'tr'
    className: 'client__docs-cell document-field-row'
