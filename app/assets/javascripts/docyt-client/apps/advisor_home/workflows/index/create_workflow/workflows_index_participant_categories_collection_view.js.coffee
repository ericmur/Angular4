@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ParticipantCategoriesCollectionItem extends Marionette.CompositeView
    template: 'advisor_home/workflows/index/create_workflow/workflows_index_participant_categories_collection_tmpl'
    childViewContainer: '.participants-docs-selects-list'

    getChildView: ->
      Index.SelectCategory

    childViewOptions: ->
      item: @model

    initialize: ->
      @model.set('categories', @options.categories) unless @model.has('categories')

    ui:
      addSelect: '.add-select-js'

    events:
      'click @ui.addSelect': 'addSelectInput'

    templateHelpers: ->
      if @isClient()
        isClient:        @isClient()
        avatarUrl:       @model.getAvatarUrl()
        participantName: @model.get('parsed_fullname')

    closeModal: ->
      @destroy()

    addSelectInput: ->
      @collection.add(new Docyt.Entities.StandardDocument())

    isClient: ->
      @model.get('type') == 'Client'
