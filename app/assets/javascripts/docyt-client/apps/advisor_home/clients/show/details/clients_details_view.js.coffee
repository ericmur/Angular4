@Docyt.module "AdvisorHomeApp.Clients.Show.Details", (Details, App, Backbone, Marionette, $, _) ->

  class Details.View extends Marionette.ItemView
    className: 'client__docs'
    template: 'advisor_home/clients/show/details/clients_details_view_tmpl'

    ui:
      clientName:     '#client-detail-name'
      clientEmail:    '#client-detail-email'
      clientPhone:    '#client-detail-phone'
      clientBirthday: '#client-detail-birthday'
      totalDocsCount: '.total-documents-count-js'

    events:
      'click @ui.totalDocsCount': 'fetchCategoriesWithClientDocuments'

    templateHelpers: ->
      isSupport:        Docyt.currentAdvisor.get('is_support')
      isConnected:      @model.isConnected()
      connectedSince:   @model.connectedSince()
      totalDocsCount:   @getTotalDocsCount()
      formatedBirthday: @model.getFormatedBirthday()

    onRender: ->
      @showClientDetails()

    getTotalDocsCount: ->
      @model.get('total_uploaded_docs_count')

    showClientDetails: =>
      @ui.clientName.show() if @model.get('parsed_fullname')
      @ui.clientBirthday.show() if @model.get('birthday')
      @ui.clientEmail.show() if @model.get('email')
      @ui.clientPhone.show() if @model.get('phone_normalized')

    fetchCategoriesWithClientDocuments: ->
      return unless @getTotalDocsCount()

      clientId   = @model.get('id')
      @categories ||= new Docyt.Entities.StandardDocuments

      if @categories.length
        @openDocumentTypesModal(@categories)
      else
        Docyt.vent.trigger('show:spinner')

        @categories.fetch(data: @setParams()).done =>
          Docyt.vent.trigger('hide:spinner')
          @openDocumentTypesModal(@categories)
        .error =>
          Docyt.vent.trigger('hide:spinner')
          toastr.error('Unable to load the client standard documents. Try again later.', 'Something went wrong.')

    openDocumentTypesModal: (categories) ->
      modalView = new Details.DocumentTypesCollectionModal
        client:     @model
        collection: categories

      Docyt.modalRegion.show(modalView)

    setParams: ->
      data =
        client_id:     @model.get('id')
        for_support:   true
        for_client_id: @model.get('id')

      data
