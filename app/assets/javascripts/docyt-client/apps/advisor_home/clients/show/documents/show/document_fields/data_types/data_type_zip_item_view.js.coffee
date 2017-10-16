@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.DataTypes", (DataTypes, App, Backbone, Marionette, $, _) ->

  class DataTypes.ZipItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/documents/show/document_fields/data_types/data_types_number_item_tmpl'

    MASK = "99999-9999"

    ui:
      dataFieldValue:         '.document-field-value'
      valueShowWrapperParent: ".value-show-wrapper"
      valueShowWrapper:       '.value-show-wrapper.zip'
      valueEditWrapper:       '.value-edit-wrapper'
      valueEditInput:         '.value-edit-input.zip'

    behaviors: 
      "DataTypeInput": {}

    onRender: ->
      @setMask()

    setMask: ->
      @ui.valueEditInput.inputmask(MASK)
      @ui.valueShowWrapper.inputmask(MASK)
