@Docyt.module "AdvisorHomeApp.ReviewDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.HeaderMenu extends Marionette.ItemView
    template:  'advisor_home/review_documents/index/review_documents_index_header_menu_tmpl'

    ui:
      assignClientButton: ".assign-btn"

    events:
      'click @ui.assignClientButton': 'openAssignClientModal'

    initialize: ->
      @checked_documents = new Docyt.Entities.Documents([])
      Docyt.vent.on('clients:review_documents:list:check', @addDocument)
      Docyt.vent.on('clients:review_documents:list:uncheck', @removeDocument)
      Docyt.vent.on('clients:review_documents:list:remove_assigned', @cleanCheckedDocuments)

    onDestroy: ->
      Docyt.vent.off('clients:review_documents:list:check')
      Docyt.vent.off('clients:review_documents:list:uncheck')
      Docyt.vent.off('clients:review_documents:list:remove_assigned')

    openAssignClientModal: ->
      if @checked_documents.length
        Docyt.vent.trigger('clients:review_documents:modal:show', @checked_documents)

    highlightAssignButton: =>
      if @checked_documents.length
        @ui.assignClientButton.addClass('active-assign-btn')
      else
        @ui.assignClientButton.removeClass('active-assign-btn')

    addDocument: (document) =>
      @checked_documents.add(document)
      @highlightAssignButton()

    removeDocument: (document) =>
      @checked_documents.remove(document)
      @highlightAssignButton()

    cleanCheckedDocuments: =>
      @checked_documents = new Docyt.Entities.Documents([])
      @highlightAssignButton()
