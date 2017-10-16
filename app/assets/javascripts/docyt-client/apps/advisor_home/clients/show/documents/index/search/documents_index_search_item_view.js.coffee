@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentSearchItemView extends Marionette.ItemView
    tagName:   'tr'
    className: 'client__docs-li'
    template:  'advisor_home/clients/show/documents/index/search/clients_documents_search_item_tmpl'

    templateHelpers: ->
      isIndexPage: @isIndexPage
      documentName: @getDocumentName()
      documentUrl: "/clients/#{@options.client.get('id')}/documents/#{@model.get('id')}"
      firstDocumentField: @getFirstDocumentField()
      secondDocumentField: @getSecondDocumentField()

    getDocumentName: ->
      if @model.has('get_standard_document_name') && @model.has('get_standard_folder_name')
        "#{@model.get('get_standard_document_name')}/#{@model.get('get_standard_folder_name')}"
      else
        @model.getTruncatedName(25)

    getFirstDocumentField: ->
      @model.get('first_standard_field') || '--'

    getSecondDocumentField: ->
      @model.get('second_standard_field') || '--'
