@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Controller extends Docyt.Common.BaseDocuments.Show.Controller

    showDocument: (clientId, documentId) ->
      client = @getClient(clientId)
      client.fetch().done =>
        @fetchDocument(documentId, client)

    getClient: (clientId) ->
      new Docyt.Entities.Client
        id: clientId
