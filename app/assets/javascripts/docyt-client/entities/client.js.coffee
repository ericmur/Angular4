@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Client extends Docyt.Entities.BaseClient
    urlRoot: -> "/api/web/v1/clients"
    paramRoot: 'client'

    initialize: ->
      @setComputedAttributes()
      @setTriggerAttributes()

    parse: (response) ->
      if response.client then response.client else response

    setComputedAttributes: ->
      @set(
        detailsUrl:   @getDetailsUrl()
        messagesUrl:  @getMessagesUrl()
        documentsUrl: @getDocumentsUrl()
        workflowsUrl: @getWorkflowsUrl()
      )

    getDocumentsUrl: ->
      "/clients/#{@get('id')}/details/documents"

    getMessagesUrl: ->
      "/clients/#{@get('id')}/messages"

    getWorkflowsUrl: ->
      "/clients/#{@get('id')}/workflows"

    getDetailsUrl: ->
      "/clients/#{@get('id')}/details"

    setTriggerAttributes: ->
      @set(
        listAllDocuments:        'list:documents'
        categoryDocuments:       'category:documents'
        searchAllDocuments:      'search:documents'
        searchDocumentsCategory: 'category:search:documents'
      )

    setTriggerAttributes: ->
      @set(
        listAllDocuments:        'list:documents'
        categoryDocuments:       'category:documents'
        searchAllDocuments:      'search:documents'
        searchDocumentsCategory: 'category:search:documents'
      )

    getFormatedBirthday: ->
      return unless @get('birthday')

      moment(@get('birthday')).format('MMMM D, YYYY')

    connectedSince: ->
      return unless @get('consumer_created_at')

      moment(@get('consumer_created_at')).format('MMM D, YYYY')
