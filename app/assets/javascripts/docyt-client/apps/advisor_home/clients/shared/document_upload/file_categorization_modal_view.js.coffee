@Docyt.module "AdvisorHomeApp.Shared", (Shared, App, Backbone, Marionette, $, _) ->

  class Shared.FilesCategorizationProgressModal extends Marionette.CompositeView
    template:  'advisor_home/clients/shared/files_categorization_modal_tmpl'
    childViewContainer: '.upload-files-wrapper'

    getChildView: ->
      Shared.FileCategorizationItemView

    ui:
      closeCross:     '.close'
      cancelLink:     '.cancel-link'
      saveCategories: '#save'

    events:
      'click @ui.closeCross':     'closeModal'
      'click @ui.cancelLink':     'closeModal'
      'click @ui.saveCategories': 'updateCategories'

    templateHelpers: ->
      files:      @options.files
      objectName: @getObjectName()

    initialize: ->
      @setCategoriesOptionsForDocuments()

      @client     = @options.client
      @business   = @options.business
      @categories = new Docyt.Entities.StandardDocuments

    closeModal: ->
      @destroy()

    setCategoriesOptionsForDocuments: ->
      @showSpinner()

    onRenderCollection: ->
      @categories.fetch(data: @setParams()).done =>
        Docyt.vent.trigger('categories:loaded', @categories)
      .always =>
        @hideSpinner()

    showSpinner: ->
      $('body').addClass('spinner-open')
      $('body').append("<div class='spinner-overlay'><i class='fa fa-spinner fa-pulse'></i></div>")

    hideSpinner: ->
      $('body').removeClass('spinner-open')
      $('.spinner-overlay').remove()

    updateCategories: ->
      @showSpinner()

      deferredRequests = []
      documents = []
      @collection.withCategories().forEach (document) =>
        document.set(business_id: @business.get('id')) if @business
        document = @setCategoryParams(document)

        deferredRequests.push(document.updateCategory())
        documents.push(document)

      $.when.apply($, deferredRequests).done =>
        Docyt.vent.trigger(@getTrigger(), documents)
        @hideSpinner()
        @destroy()

    setParams: ->
      data =
        if @client
          client_id:   @client.get('id')
          client_type: @client.get('type')

      data

    setCategoryParams: (document) ->
      document.set(
        standard_document:
          id:   document.get('category_id')
          name: document.get('category_name')
          is_user_created: document.get('is_user_created_category')
      )

      document

    getTrigger: ->
      if @client
        'uploaded:document:update:category' if @client.get('get_structure_type') == 'flat'
      else
        'uploaded:document:remove:from:uncategorized'

    getObjectName: ->
      return @client.get('parsed_fullname') if @client

      @business.get('name')
