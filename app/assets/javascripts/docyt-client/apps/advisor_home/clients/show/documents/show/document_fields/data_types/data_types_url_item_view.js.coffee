@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.DataTypes", (DataTypes, App, Backbone, Marionette, $, _) ->

  class DataTypes.UrlItemView extends Marionette.ItemView
    template:  'advisor_home/clients/show/documents/show/document_fields/data_types/data_types_url_item_tmpl'

    ui:
      dataFieldValue:         '.document-field-value'
      valueShowWrapperParent: ".value-show-wrapper"
      valueShowWrapper:       '.value-show-wrapper.url'
      valueEditWrapper:       '.value-edit-wrapper'
      valueEditInput:         '.value-edit-input'

    behaviors: 
      "DataTypeInput": {}
