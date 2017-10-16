@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Business extends Backbone.Model
    urlRoot: -> "/api/web/v1/businesses"
    paramRoot: 'business'

    initialize: ->
      @set('selAcctUrl', @getSelAcctUrl())

    parse: (response) ->
      if response.business then response.business else response

    getBizAvatarUrl: ->
      return unless @has('avatar')

      "https://#{configData.bucketName}.s3.amazonaws.com/#{@get('avatar').s3_object_key}"

    getSelAcctUrl: ->
      "/sign_up/account_type_selection"
