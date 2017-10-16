@Docyt.module "AdvisorHomeApp.LatestDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentItemView extends Marionette.ItemView
    template: 'advisor_home/latest_documents/index/documents/latest_documents_index_document_item_tmpl'
    className: 'latest-document-li'

    templateHelpers: ->
      createdAt: moment(@model.get('created_at')).format('lll')
      updatedAt: moment(@model.get('updated_at')).format('lll')
