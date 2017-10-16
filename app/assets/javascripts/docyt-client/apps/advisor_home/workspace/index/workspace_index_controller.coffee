@Docyt.module "AdvisorHomeApp.Workspace.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Controller extends Marionette.Object

    showWorkspaces: ->
      businesses = @getBusinesses()
      businesses.fetch().done =>
        accountTypes = @getConsumerAccountTypes()
        accountTypes.fetch(url: '/api/web/v1/consumer_account_types').done =>
          App.mainRegion.show(@getSelectWorkspaceColletionView(businesses, accountTypes))

    getSelectWorkspaceColletionView: (businesses, accountTypes) ->
      new Docyt.AdvisorHomeApp.Workspace.Index.WorkspacesList
        model:        Docyt.currentAdvisor
        collection:   businesses
        accountTypes: accountTypes

    getBusinesses: ->
      new Docyt.Entities.Businesses

    getConsumerAccountTypes: ->
      new Docyt.Entities.ConsumerAccountTypes
