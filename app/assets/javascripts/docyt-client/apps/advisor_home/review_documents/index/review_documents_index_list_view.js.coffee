@Docyt.module "AdvisorHomeApp.ReviewDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentsListView extends Marionette.CompositeView
    className: 'docs-table'
    tagName:  'table'
    template: 'advisor_home/review_documents/index/review_documents_index_list_tmpl'

    ui:
      checkAllCheckbox: '#checkbox-all'
      assignButton:     '.assign-btn'

    events:
      'click @ui.checkAllCheckbox': 'checkAllDocuments'

    initialize: ->
      Docyt.vent.on('clients:review_documents:list:uncheck', @uncheckAllCheckbox)
      Docyt.vent.on('clients:review_documents:list:remove_assigned', @removeDocumentFromList)

    onDestroy: ->
      Docyt.vent.off('clients:review_documents:list:uncheck')
      Docyt.vent.off('clients:review_documents:list:remove_assigned')

    getChildView: ->
      Index.DocumentItemView

    checkAllDocuments: ->
      @children.each (itemView) =>
        itemView.triggerMethod('setDocumentCheckbox', @ui.checkAllCheckbox.is(':checked'))

    uncheckAllCheckbox: =>
      @ui.checkAllCheckbox.prop('checked', false)

    removeDocumentFromList: (assigned_documents) =>
      _.each assigned_documents, (document) =>
          @collection.remove(document.id)
