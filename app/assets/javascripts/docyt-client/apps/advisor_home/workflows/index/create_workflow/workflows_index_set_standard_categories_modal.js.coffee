@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.SetStandardCategoriesModal extends Marionette.CompositeView
    template: 'advisor_home/workflows/index/create_workflow/workflows_index_set_standard_categories_modal_tmpl'
    childViewContainer: '.participants-list'

    getChildView: ->
      Index.ParticipantCategoriesCollectionItem

    childViewOptions: (item) ->
      collection: item.get('standard_documents')
      categories: @categories

    initialize: ->
      @loadCategories()
      @isChecked = false

    ui:
      back:   '.back-js'
      cancel: '.cancel-js'
      submit: '.submit-js'

      checkbox:      '.checkbox-js'
      checkboxLabel: '.workflow-participants-switch-js'

      errorCategories: '.categories-not-added-js'

    events:
      'click @ui.back':   'previousStep'
      'click @ui.cancel': 'closeModal'
      'click @ui.submit': 'createWorkflow'

      'click @ui.checkboxLabel': 'switchCategoriesOwner'

    closeModal: ->
      @destroy()

    onRender: ->
      @ui.errorCategories.hide()
      @toggleCheckbox()

    previousStep: ->
      modalView = new Index.SelectParticipantsModal
        workflow: @options.workflow
        collection: @options.workflow.get('participants')

      Docyt.modalRegion.show(modalView)
      @resetSelectedCategories()
      @destroy()

    switchCategoriesOwner: (e) ->
      e.preventDefault()

      @resetSelectedCategories()

      if @isChecked
        @isChecked = false
        @collection = @options.workflow.get('participants')
      else
        @isChecked = true
        @collection = new Docyt.Entities.Workflows(@options.workflow)
      @options.workflow.set('same_documents_for_all', @isChecked)
      @render()

    toggleCheckbox: ->
      if @isChecked
        @ui.checkbox.prop('checked', @isChecked)
      else
        @ui.checkbox.removeAttr('checked')

    loadCategories: ->
      unless _.every(@collection.models, (model) -> model.has('categories'))
        Docyt.vent.trigger('show:spinner')

        @categories = new Docyt.Entities.StandardDocuments

        @categories.fetch().always =>
          Docyt.vent.trigger('hide:spinner')

    createWorkflow: ->
      @clearCategories()
      @options.workflow.save().success (response) =>
        Docyt.vent.trigger('workflow:created', response)
        @destroy()
      .error =>
        toastr.error('Create failed. Please try again.', 'Something went wrong.')

    clearCategories: ->
      @options.workflow.unset('categories', silent: true) if @options.workflow.has('categories')

      _.each(@options.workflow.get('participants').models, (model) ->
        model.unset('categories', silent: true) if model.has('categories')
      )

    resetSelectedCategories: ->
      _.each(@collection.models, (model) -> model.get('standard_documents').reset())
