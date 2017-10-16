@Docyt.module "AdvisorHomeApp.Clients.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.SideMenu extends Marionette.ItemView
    tagName:  'aside'
    template: 'advisor_home/clients/show/clients_side_menu_tmpl'

    ui:
      documentsNav: '#documents-nav'
      messagesNav:  '#messages-nav'
      detailsNav:   '#details-nav'

    templateHelpers: ->
      avatarUrl: @model.getAvatarUrl()

    initialize: ->
      @listenTo(@model, 'change', @render)
      Docyt.vent.on('file:upload:success', @addUploadedDocument)
      Docyt.vent.on('file:destroy:success', @removeDocument)

    onDestroy: ->
      Docyt.vent.off('file:upload:success')
      Docyt.vent.off('file:destroy:success')

    addUploadedDocument: (uploadedDocWithClientId) =>
      @model.set('all_documents_count', @model.get('all_documents_count')+1)

    updateDocumentsCountFromBoxes: (documentsCountFromBoxes) =>
      currentDocumentsCount = @model.get('all_documents_count')
      @model.set('documents_count', currentDocumentsCount+documentsCountFromBoxes)

    removeDocument: =>
      @model.set('all_documents_count', @model.get('all_documents_count')-1)

    onRender: ->
      @highlightActiveNav()

    highlightActiveNav: ->
      switch @options.activeSubmenu
        when 'documents'
          @ui.documentsNav.addClass('client__nav-li--active')
        when 'messages'
          @ui.messagesNav.addClass('client__nav-li--active')
        when 'details'
          @ui.detailsNav.addClass('client__nav-li--active')
