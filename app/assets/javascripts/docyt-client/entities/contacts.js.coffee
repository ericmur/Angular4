@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Contacts extends Backbone.Collection
    model: Docyt.Entities.Contact
    url: -> "/api/web/v1/contacts"

    parse: (response) ->
      @pagesCount = response.meta.pages_count if response.meta
      response.contacts
