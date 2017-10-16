@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.DataTypes", (DataTypes, App, Backbone, Marionette, $, _) ->

  class DataTypes.LocationItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/documents/show/document_fields/data_types/data_types_location_item_tmpl'

    ui:
      dataFieldValue: '.document-field-value'
      valueEditInput:   '.value-edit-input'

    onRender: ->
      @initSelectize()

    initSelectize: ->
      @selectizeSelect = @ui.valueEditInput.selectize
        items: [@model.get('value')]
        searchField: 'text'
        create: false
        options: @getList()
        onChange: (value) =>
          @updateOrCreateValue(value) if value

    getList: ->
      return usaStateList if @model.get('data_type') == 'state'
      return countryList if @model.get('data_type') == 'country'
      []

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
