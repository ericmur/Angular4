@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.DataTypes", (DataTypes, App, Backbone, Marionette, $, _) ->

  class DataTypes.CurrencyItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/documents/show/document_fields/data_types/data_types_number_item_tmpl'

    ui:
      dataFieldValue:         '.document-field-value'
      valueShowWrapperParent: ".value-show-wrapper"
      valueShowWrapper:       '.value-show-wrapper.currency'
      valueEditWrapper:       '.value-edit-wrapper'
      valueEditInput:         '.value-edit-input.currency'

    behaviors: 
      "DataTypeInput": {}

    onRender: ->
      @setMask()

    setMask: ->
      @ui.valueEditInput.inputmask('decimal', { radixPoint: ".", autoGroup: true, groupSeparator: ',', digits: 2, groupSize: 3 })
      @ui.valueShowWrapper.inputmask('decimal', { radixPoint: ".", autoGroup: true, groupSeparator: ',', digits: 2, groupSize: 3 })
