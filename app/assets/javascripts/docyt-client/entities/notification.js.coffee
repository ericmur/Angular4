@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Notification extends Backbone.Model

    initialize: ->
      @setUrl()

    setUrl: ->
      @set('entityUrl', @getEntityUrl())

    getEntityUrl: ->
      return unless @get('notifiable')
      type = @get('notifiable_type')
      switch type
        when 'Invitationable::Invitation'
          "/clients/#{@attributes.notifiable.client_id}/details"
        when 'DocumentFieldValue'
          "/document/#{@attributes.notifiable.document_id}"
        when 'Document'
          "/document/#{@attributes.notifiable.id}"
        when 'GroupUser'
          "/clients/#{@get('recipient_id')}-Client/details/documents/contacts/#{@attributes.notifiable.id}/GroupUser"
        when 'Invitationable::AdvisorToConsumerInvitation'
          "/clients/#{@attributes.notifiable.client_id}/details"
        when 'Page'
          "/document/#{@attributes.notifiable.document_id}"
