@Docyt.module "Behaviors", (Behaviors, App, Backbone, Marionette, $, _) ->

  class Behaviors.DataTypeInput extends Marionette.Behavior
    events:
      'click @ui.dataFieldValue':      'editFieldValue'
      'focusout @ui.valueEditWrapper': 'turnOffEditing'
      'keypress @ui.valueEditWrapper': 'updateOnEnterKeypress'

    templateHelpers: ->
      isEmpty: 'empty' unless @view.model.value

    hideObject: (object) ->
      object.removeClass("visible")

    showObject: (object) ->
      object.addClass("visible")

    showEditInput: ->
      @hideErrors()
      @hideObject(@ui.valueShowWrapperParent)
      @showObject(@ui.valueEditWrapper)

    hideEditInput: ->
      @hideObject(@ui.valueEditWrapper)
      @showObject(@ui.valueShowWrapperParent)

    editFieldValue: ->
      @showEditInput()
      @ui.valueEditInput.focus()

    turnOffEditing: ->
      if @pressEnter then @pressEnter = false else @updateOrCreateValue()
      @hideEditInput()

    updateOnEnterKeypress: (event) ->
      if event.which == 13
        @pressEnter = true
        @updateOrCreateValue()
        @hideEditInput()

    updateOrCreateValue: ->
      @hideErrors()
      valueField = new Docyt.Entities.DocumentFieldValue()
      valueField.set('input_value', @ui.valueEditInput.val())
      valueField.set('local_standard_document_field_id', @view.model.get('field_id'))
      valueField.set('document_field_id', @view.model.get('id'))

      return @ui.valueEditInput.val(@view.model.get("value")) unless @ui.valueEditInput.val()
      return @create(valueField) unless @view.model.get("value_id")?
      @update(valueField) unless @view.model.get("value") == valueField.get("input_value")

    create: (valueField) ->
      valueField.create(@view.options.documentId).success =>
        @reRenderValue(valueField)
      .error =>
        @showErrors()

    update: (valueField) ->
      valueField.set('id', @view.model.get('value_id'))
      valueField.update(@view.options.documentId).success =>
        @reRenderValue(valueField)
      .error =>
        @showErrors()

    reRenderValue: (valueField) ->
      @view.model.set('value', valueField.get('value'))
      @view.model.set('value_id', valueField.get('id'))
      @view.render()

    showErrors: ->
      @ui.dataFieldValue.addClass('unvalid')

    hideErrors: ->
      @ui.dataFieldValue.removeClass('unvalid')
