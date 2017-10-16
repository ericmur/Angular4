@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.SelectWorkflowTypeModal extends Marionette.ItemView
    template: 'advisor_home/workflows/index/create_workflow/workflows_index_select_type_modal_tmpl'

    WORKFLOW_TYPES = ['document requests', 'client agreement', 'onboarding q/a']

    ui:
      cancel: '.cancel-js'
      submit: '.submit-js'

      workflowType: '.select-type-js'

      typeNotSelectedError: '.type-not-selected-js'

    events:
      'click @ui.cancel': 'closeModal'
      'click @ui.submit': 'nextStep'

      'click @ui.workflowType': 'addTypeToWorkflow'

    closeModal: ->
      @destroy()

    onRender: ->
      @ui.typeNotSelectedError.hide()
      @setSelectedItems()

    nextStep: ->
      if @model.get('elements').length == 0
        @ui.typeNotSelectedError.show()
      else
        modalView = new Index.SetWorkflowInfoModal
          model: @model

        Docyt.modalRegion.show(modalView)
        @destroy()

    addTypeToWorkflow: (e) ->
      workflowType  = e.currentTarget.getElementsByClassName('workflow-type-title')[0].textContent.toLowerCase()
      permittedType = _.contains(WORKFLOW_TYPES, workflowType)

      elements = @setElements(@model.get('elements'), workflowType, permittedType)

      @ui.workflowType.toggleClass('selected', _.contains(elements, workflowType))
      @model.set('elements', elements)

    setElements: (elements, workflowType, permittedType) ->
      if _.contains(elements, workflowType)
        elements = _.without(elements, workflowType) if permittedType
      else
        elements.push(workflowType) if permittedType

      elements

    setSelectedItems: ->
      if @model.get('elements').length > 0
        _.each(@model.get('elements'), (element) =>
          @ui.workflowType.toggleClass('selected', true)
        )
