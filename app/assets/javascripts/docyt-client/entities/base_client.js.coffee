@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.BaseClient extends Backbone.Model

    getAvatarUrl: ->
      return if !@has('avatar')

      s3_object_key = @get('avatar').s3_object_key
      "https://#{configData.bucketName}.s3.amazonaws.com/#{s3_object_key}"

    hasContacts: ->
      _.any([@get('contacts_count'), @get('contractors_count'), @get('employees_count')], (count) ->
        count
      )

    isConnected: ->
      @has('user_id')

    getName: ->
      @get('parsed_fullname')
