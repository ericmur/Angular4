@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.DataTypes", (DataTypes, App, Backbone, Marionette, $, _) ->

  class DataTypes.IntItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/documents/show/document_fields/data_types/data_types_number_item_tmpl'

    ui:
      dataFieldValue:         '.document-field-value'
      valueShowWrapper:       '.value-show-wrapper.int'
      valueShowWrapperParent: ".value-show-wrapper"
      valueEditWrapper:       '.value-edit-wrapper'
      valueEditInput:         '.value-edit-input.int'

    behaviors: 
      "DataTypeInput": {}

    onRender: ->
      @setMask()

    setMask: ->
      @ui.valueEditInput.inputmask('decimal', { autoGroup: true, groupSeparator: ' ', digits: 0, groupSize: 3})
      @ui.valueShowWrapper.inputmask('decimal', { autoGroup: true, groupSeparator: ' ', digits: 0, groupSize: 3})
