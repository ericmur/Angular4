@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Documents extends Backbone.Collection
    model: Docyt.Entities.Document
    url: -> "/api/web/v1/documents"

    comparator: (document) ->
      # collection will reverse-sorted by date by default now
      - new Date(document.get('created_at'))

    withCategories: ->
      @filter (doc) ->
        is_user_created = doc.get('is_user_created_category')
        category_id     = doc.get('category_id')
        doc if (category_id != '' && category_id != undefined) || is_user_created

    parse: (response) ->
      response.documents

    assignToClient: (clientId, documentIds, contactId = null, contactType = null) ->
      params =
        url: "/api/web/v1/documents/assign"
        dataType: 'json'
        contentType: 'application/json'
        data:
          JSON.stringify(
            client_id:    clientId,
            contact_type: contactType,
            contact_id:   contactId,
            shared_documents:
              ids: documentIds,
          )

      Backbone.sync('update', @, params)

    fetchWithSearch: (data) ->
      @fetch(url: "/api/web/v1/documents/search", data: data)

    fetchForAdvisorViaEmail: ->
      @fetch(url: "/api/web/v1/advisor/documents/documents_via_email")

    relevantCategory: (category) ->
      _.every(@models, (document) ->
        standardDocument = document.get('standard_document')

        if standardDocument
          document.get('standard_document').standard_folder_id == category.get('id')
      )
