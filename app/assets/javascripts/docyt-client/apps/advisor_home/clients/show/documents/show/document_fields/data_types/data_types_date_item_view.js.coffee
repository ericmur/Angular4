@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.DataTypes", (DataTypes, App, Backbone, Marionette, $, _) ->

  class DataTypes.DateItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/documents/show/document_fields/data_types/data_types_date_item_tmpl'

    ui:
      dataFieldValue: '.document-field-value'
      valueEditInput: '.value-edit-input'

    onRender: ->
      @initPickadate()

    initPickadate: ->
      @pickadate = @ui.valueEditInput.pickadate
        set: @model.get('value')
        format: 'mm/dd/yyyy'
        onSet: (context) =>
          date = new Date(context.select)
          @formated_date = @formatDateForSave(date)
        onClose: =>
          @updateOrCreateValue(@formated_date) if @formated_date

    correctDateNumber: (number) ->
      return number if number > 9
      "0#{number}"

    formatDateForSave: (date) ->
      day = @correctDateNumber(date.getDate())
      month = @correctDateNumber(date.getMonth()+1)
      "#{month}/#{day}/#{date.getFullYear()}"

    updateOrCreateValue: (value) ->
      @hideErrors()
      valueField = new Docyt.Entities.DocumentFieldValue()
      valueField.set('input_value', value)
      valueField.set('local_standard_document_field_id', @model.get('field_id'))
      valueField.set('document_field_id', @model.get('id'))

      return @create(valueField) unless @model.get("value_id")?
      @update(valueField) unless @model.get("value") == valueField.get("input_value")

    create: (valueField) ->
      valueField.create(@options.documentId).success =>
        @reRenderValue(valueField)
      .error =>
        @showErrors()

    update: (valueField) ->
      valueField.set('id', @model.get('value_id'))
      valueField.update(@options.documentId).success =>
        @reRenderValue(valueField)
      .error =>
        @showErrors()

    reRenderValue: (valueField) ->
      @model.set('value', valueField.get('value'))
      @model.set('value_id', valueField.get('id'))

    showErrors: ->
      @ui.dataFieldValue.addClass('unvalid')

    hideErrors: ->
      @ui.dataFieldValue.removeClass('unvalid')
