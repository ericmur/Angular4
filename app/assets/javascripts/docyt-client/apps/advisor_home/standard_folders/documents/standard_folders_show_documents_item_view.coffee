@Docyt.module "AdvisorHomeApp.StandardFolders.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentView extends Marionette.ItemView
    template:  'advisor_home/standard_folders/documents/standard_folders_show_documents_item_tmpl'

    initialize: ->
      @business         = @options.business
      @standardDocument = @model.get('standard_document')

    templateHelpers: ->
      detailsUrl: @getDocumentUrl()

    getDocumentUrl: ->
      if @business
        @linkForCategorizedBusinessDocument()
      else
        "my_documents/#{@standardDocument.standard_folder_id}/documents/#{@model.get('id')}"

    linkForCategorizedBusinessDocument: ->
      if @standardDocument
        "businesses/#{@business.get('id')}/standard_folders/#{@standardDocument.standard_folder_id}/documents/#{@model.get('id')}"
      else
        '#'
