@Docyt.module "AdvisorHomeApp.ReviewDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentItemView extends Marionette.ItemView
    className: 'docs-item'
    tagName:  'tr'
    template: 'advisor_home/review_documents/index/review_documents_index_item_tmpl'

    ui:
      emailContent:   '.docs-item-content-icon'
      checkDocument:  '.custom-checkbox'
      linkToDocument: '.docs-item-filename a'

    events:
      'click':                    'toggleDocumentCheckbox'
      'click @ui.emailContent':   'showEmailContentModal'
      'click @ui.linkToDocument': 'showDocument'

    templateHelpers: ->
      truncatedDocumentName: @model.getTruncatedName(30)

    toggleDocumentCheckbox: =>
      @onSetDocumentCheckbox(!@ui.checkDocument.is(':checked'))

    onSetDocumentCheckbox: (state) =>
      @ui.checkDocument.prop('checked', state)
      @toggleAssignButton()

    toggleAssignButton: ->
      if @ui.checkDocument.is(':checked')
        Docyt.vent.trigger('clients:review_documents:list:check', @model)
      else
        Docyt.vent.trigger('clients:review_documents:list:uncheck', @model)

    showEmailContentModal: (e) ->
      e.stopPropagation()
      Docyt.vent.trigger('clients:review_documents:email:modal:show', @model)

    showDocument: (e) ->
      e.stopPropagation()
      Backbone.history.navigate("/review_documents/#{@model.get('id')}", { trigger: true })
