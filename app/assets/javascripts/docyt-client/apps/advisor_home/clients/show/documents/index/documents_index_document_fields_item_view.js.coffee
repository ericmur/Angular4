@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentFieldItemView extends Marionette.ItemView
    template: -> @getTemplate()
    tagName: -> @getTagName()
    className: -> @getClassName()

    getTagName: ->
      if @options.isDocumentFieldsModal then 'tr' else 'td'

    getTemplate: ->
      if @options.isDocumentFieldsModal
        'advisor_home/clients/show/documents/index/clients_documents_document_fields_modal_tmpl'
      else
        'advisor_home/clients/show/documents/index/clients_documents_document_fields_tmpl'

    getClassName: ->
      if @options.isDocumentFieldsModal
        'client__docs-cell document-field-row'
      else
        "client__docs-cell client__docs-li-title open-document"

    templateHelpers: ->
      field_name: @getName(@model.get('name'))
      field_value: @getName(@model.get('value'))

    getName: (name) ->
      name = $.trim(name)
      if name.length > 30
        "#{name.substring(0, 30)} ..."
      else
        name
