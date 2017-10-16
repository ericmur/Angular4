@Docyt.module "SignUpApp.AccountTypeSelection", (AccountTypeSelection, App, Backbone, Marionette, $, _) ->

  class AccountTypeSelection.SelectAdvisorCategory extends Marionette.ItemView
    template: 'sign_up/account_type_selection/select_category_modal_tmpl'

    ui:
      cancel:  '.cancel-js'
      confirm: '.confirm-js'

      advisorTypeSelect:  '#type-menu'
      advisorTypeOption:  '.login-form__select-menu-item'
      advisorTypeOptions: '#select-options'
      advisorTypeInvalid: '#advisor-type-invalid'

      advisorTypeSelectedOption: '#selected-option'

    events:
      'click @ui.cancel':  'destroy'
      'click @ui.confirm': 'submitModal'

      'click @ui.advisorTypeSelect': 'showSelectOptions'
      'click @ui.advisorTypeOption': 'setAdvisorType'

    initialize: ->
      @initSelectHideHandler()

    onDestroy: ->
      $(document).off('click')

    templateHelpers: ->
      advisorTypes: @options.advisorTypes.toJSON()

    initSelectHideHandler: ->
      $(document).click (e) => @ui.advisorTypeOptions.hide()

    showSelectOptions: (e) ->
      e.stopPropagation()
      @ui.advisorTypeOptions.show()

    setAdvisorType: (e) ->
      @ui.advisorTypeSelectedOption.text(e.currentTarget.textContent)
      @advisorType = e.currentTarget.dataset.option
      @ui.advisorTypeOptions.hide()

    submitModal: ->
      @ui.advisorTypeInvalid.hide()

      businessType = @options.accountTypes.getType('Business')
      @model.set(standard_category_id: @advisorType, current_workspace_id: businessType.get('id'))

      return @ui.advisorTypeInvalid.show() unless @model.get('standard_category_id')

      @model.save({}, url: "/api/web/v1/advisor/#{@model.get('id')}").done =>
        Backbone.history.navigate("/clients", trigger: true)
        Docyt.vent.trigger('current:advisor:updated')
        @destroy()
