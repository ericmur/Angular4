@Docyt.module "AdvisorHomeApp.ReviewDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.AssignClientModal extends Marionette.CompositeView
    childViewContainer: 'table'
    childView: Index.AssignClientItemView
    template: 'advisor_home/review_documents/index/review_documents_index_assign_client_modal_tmpl'

    ui:
      cancel: '.cancel'
      save:   '.save'

    events:
      'click @ui.cancel': 'closeModal'
      'click @ui.save':   'submitModal'
      'click tr':         'selectClient'

    initialize: ->
      @client = null

    templateHelpers: ->
      if @options.documents
        documentsSelected: @options.documents.length

    getDocuments: ->
      new Docyt.Entities.Documents()

    closeModal: ->
      @destroy()

    selectClient: (e) ->
      client_id = $(e.currentTarget).data('id')
      @client = @collection.get(client_id)
      unless @client
        owner_client_id = $(e.currentTarget).parent().data('id')
        owner_client = @collection.get(owner_client_id)
        @client = owner_client.contacts.get(client_id)
        @client.set('ownerClientId', owner_client_id)
      Docyt.vent.trigger("client:selected", client_id)

    submitModal: =>
      unless @client?
        @destroy()
      else
        documentIds = @options.documents.map (doc) -> doc.id
        documents = @getDocuments()
        documents.assignToClient(@isClient(@client), documentIds, @client.get('id'), @client.get("type")).success (data) =>
          Docyt.vent.trigger('clients:review_documents:list:remove_assigned', data.documents)
        @destroy()

    isClient: (model) ->
      return model.get('ownerClientId') if model.has('ownerClientId')
      model.get('id')

