@Docyt.module "AdvisorHomeApp.Workspace.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.WorkspacesList extends Marionette.CompositeView
    template:  'advisor_home/workspace/index/workspaces_collection_tmpl'
    className: 'clients__wrap'

    childViewContainer: '.business-workspaces-list'

    getChildView: ->
      Index.WorkspaceItem

    onRender: ->
      Docyt.vent.on('business:workspace:selected', @setBusinessWorkspace)

    onDestroy: ->
      Docyt.vent.off('business:workspace:selected')

    ui:
      individualWorkspace: '.select-individual-js'

    events:
      'click @ui.individualWorkspace': 'setIndividualWorkspace'

    templateHelpers: ->
      avatarUrl: @model.getAdvisorAvatarUrl()

    setBusinessWorkspace: (business) =>
      @setAdvisorWorkspace(business)

      @updateCurrentWorkspace()

    setIndividualWorkspace: ->
      @setAdvisorWorkspace(@options.accountTypes.getType('Family'))

      @updateCurrentWorkspace()

    setAdvisorWorkspace: (type) ->
      @model.set(
        current_workspace_id:   type.get('id')
        current_workspace_name: type.get('display_name')
      )

    updateCurrentWorkspace: ->
      @model.save({}, url: "/api/web/v1/advisor/#{@model.get('id')}").done =>
        Docyt.vent.trigger('current:advisor:updated')
        @navigateAdvisor()

    navigateAdvisor: ->
      if @model.get('current_workspace_name') == 'Business'
        Backbone.history.navigate('/businesses/' + @model.get('current_workspace_id') + '/standard_folders', trigger: true)
      else
        Backbone.history.navigate('/my_documents', trigger: true)
