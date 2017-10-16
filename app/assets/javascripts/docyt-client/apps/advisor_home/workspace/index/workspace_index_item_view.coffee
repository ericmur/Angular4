@Docyt.module "AdvisorHomeApp.Workspace.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.WorkspaceItem extends Marionette.ItemView
    template:  'advisor_home/workspace/index/workspace_item_tmpl'
    className: 'workspace-col'

    ui:
      businessWorkspace: '.select-bussiness-js'

    events:
      'click @ui.businessWorkspace': 'setBusinessWorkspace'

    templateHelpers: ->
      avatarUrl: @model.getBizAvatarUrl()

    setBusinessWorkspace: ->
      @model.set('display_name', 'Business')
      Docyt.vent.trigger('business:workspace:selected', @model)
