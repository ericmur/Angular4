@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentFieldsList extends Marionette.CompositeView
    template: 'advisor_home/clients/show/documents/show/document_fields/document_fields_list_tmpl'
    childViewContainer: ".document-fields"

    getChildView: (child) ->
      data_type = child.get('data_type')

      switch data_type
        when 'float'
          @getViewLocation('FloatItemView')
        when 'int'
          @getViewLocation('IntItemView')
        when 'expiry_date'
          @getViewLocation('DateItemView')
        when 'due_date'
          @getViewLocation('DateItemView')
        when 'date'
          @getViewLocation('DateItemView')
        when 'year'
          @getViewLocation('YearItemView')
        when 'zip'
          @getViewLocation('ZipItemView')
        when 'state' || 'country'
          @getViewLocation('LocationItemView')
        when 'url'
          @getViewLocation('UrlItemView')
        when 'boolean'
          @getViewLocation('BooleanItemView')
        when 'phone'
          @getViewLocation('PhoneItemView')
        when 'currency'
          @getViewLocation('CurrencyItemView')
        when 'string'
          @getViewLocation('StringItemView')
        when 'text'
          @getViewLocation('TextItemView')
        else
          Index.DocumentFieldItemView

    getViewLocation: (name) ->
      Docyt.AdvisorHomeApp.Clients.Show.Documents.Show.DocumentFields.DataTypes[name]

    childViewOptions: ->
      documentId: @options.documentId
