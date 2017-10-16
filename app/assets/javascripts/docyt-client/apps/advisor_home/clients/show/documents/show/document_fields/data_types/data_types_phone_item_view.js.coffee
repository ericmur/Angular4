@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.DataTypes", (DataTypes, App, Backbone, Marionette, $, _) ->

  class DataTypes.PhoneItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/documents/show/document_fields/data_types/data_types_number_item_tmpl'

    MASK = "(999) 999-9999"

    ui:
      dataFieldValue:         '.document-field-value'
      valueShowWrapperParent: ".value-show-wrapper"
      valueShowWrapper:       '.value-show-wrapper.phone'
      valueEditWrapper:       '.value-edit-wrapper'
      valueEditInput:         '.value-edit-input.phone'

    behaviors: 
      "DataTypeInput": {}

    onRender: ->
      @setMask()

    setMask: ->
      @ui.valueEditInput.inputmask(MASK)
      @ui.valueShowWrapper.inputmask(MASK)
