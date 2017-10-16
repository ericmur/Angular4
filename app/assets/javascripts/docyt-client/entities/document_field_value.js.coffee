@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.DocumentFieldValue extends Backbone.Model

    update: (documentId) ->
      @save(
        {
          document_field_value:
            id: @get('id')
            input_value: @get('input_value')
            document_field_id: @get("document_field_id")
            local_standard_document_field_id: @get('local_standard_document_field_id')
        },
        url: "/api/web/v1/documents/#{documentId}/document_field_values/#{@get('id')}"
        success: (response) =>
          @set(response)
      )

    create: (documentId) ->
      @save(
        {
          document_field_value:
            document_id: documentId
            input_value: @get('input_value')
            document_field_id: @get("document_field_id")
            local_standard_document_field_id: @get('local_standard_document_field_id')
        },
        url: "/api/web/v1/documents/#{documentId}/document_field_values"
        success: (response) =>
          @set(response)
      )

    parse: (response) ->
      response.document_field_value
