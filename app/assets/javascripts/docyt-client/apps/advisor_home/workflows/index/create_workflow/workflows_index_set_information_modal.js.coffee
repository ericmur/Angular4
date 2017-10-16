@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.SetWorkflowInfoModal extends Marionette.ItemView
    template: 'advisor_home/workflows/index/create_workflow/workflows_index_set_information_modal_tmpl'

    ui:
      back:   '.back-js'
      cancel: '.cancel-js'
      submit: '.submit-js'

      nameInput:    '.name-input-js'
      purposeInput: '.purpose-input-js'
      endDateInput: '.end-date-input-js'

      nameError:    '.name-invalid'
      purposeError: '.purpose-invalid'
      endDateError: '.end-date-invalid'

    events:
      'click @ui.back':   'previousStep'
      'click @ui.cancel': 'closeModal'
      'click @ui.submit': 'nextStep'

    templateHelpers: ->
      workflowName: @model.get('name') || ''
      workflowPurpose: @model.get('purpose') || ''

    closeModal: ->
      @destroy()

    onRender: ->
      @initPickadate()

    initPickadate: ->
      input = @ui.endDateInput.pickadate
        container: 'body'
        min: 2
        max: 0
        onSet: (context) =>
          date = new Date(context.select)
          @model.set('end_date', date)
        onClose: =>
          @ui.nameInput.focus()

      date = @getDateFromWorkFlow()
      input.pickadate('picker').set('select', date)

    nextStep: ->
      @hideAllErrors()
      @setWorkflowName()
      @setWorkflowPurpose()
      @ui.endDateError.show() unless @model.has('end_date')

      if @model.has('name') && @model.has('purpose') && @model.has('end_date')
        @selectParticipantsModal()

    setWorkflowName: ->
      name = $.trim(@ui.nameInput.val().replace(/\s\s+/g, ' '))

      if name.length > 0
        @ui.nameInput.val(name)
        @model.set('name', name)
      else
        @ui.nameError.show()

    setWorkflowPurpose: ->
      purpose = $.trim(@ui.purposeInput.val().replace(/\s\s+/g, ' '))

      if purpose.length > 0
        @ui.purposeInput.val(purpose)
        @model.set('purpose', purpose)
      else
        @ui.purposeError.show()

    hideAllErrors: ->
      @ui.nameError.hide()
      @ui.purposeError.hide()
      @ui.endDateError.hide()

    previousStep: ->
      modalView = new Index.SelectWorkflowTypeModal
        model: @model

      @appendNewModal(modalView)

    selectParticipantsModal: ->
      modalView = new Index.SelectParticipantsModal
        workflow:   @model
        collection: @model.get('participants')

      @appendNewModal(modalView)

    appendNewModal: (modalView) ->
      Docyt.modalRegion.show(modalView)
      @destroy()

    getDateFromWorkFlow: ->
      new Date(@model.get('end_date')) if @model.has('end_date')
