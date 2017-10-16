@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.StandardFoldersList extends Marionette.CompositeView
    template: 'advisor_home/clients/show/documents/standard_folders/index/standard_folders_list_tmpl'
    childViewContainer: ".client-row"

    initialize: ->
      Docyt.vent.on('category:changed', @createNewFolder)
      @client   = @options.client
      @contact  = @options.contact
      @business = @options.business

    getChildView: ->
      Index.StandardFolderItemView

    childViewOptions: ->
      client:   @client
      contact:  @contact
      business: @business

      ownDocuments: @options.ownDocuments
