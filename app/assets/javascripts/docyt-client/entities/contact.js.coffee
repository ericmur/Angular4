@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Contact extends Docyt.Entities.BaseClient
    urlRoot: -> "/api/web/v1/contacts"
    paramRoot: 'contact'

    initialize: ->
      @setUrlAttributes()
      @setTriggerAttributes()

    parse: (response) ->
      if response.contact then response.contact else response

    setUrlAttributes: ->
      @set(
        detailsUrl:   "contacts/#{@get('id')}/details"
        messagesUrl:  "contacts/#{@get('id')}/messages"
        documentsUrl: "contacts/#{@get('id')}/details/documents"
      )

    setTriggerAttributes: ->
      @set(
        listAllDocuments:        'contact:list:documents'
        categoryDocuments:       'contact:category:documents'
        searchAllDocuments:      'contact:search:documents'
        searchDocumentsCategory: 'contact:category:search:documents'
      )
