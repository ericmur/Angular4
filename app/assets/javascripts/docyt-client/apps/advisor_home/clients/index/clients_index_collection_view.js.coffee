@Docyt.module "AdvisorHomeApp.Clients.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ClientsList extends Marionette.CollectionView
    childView: Index.ClientView

    PERCENT_FROM_TOP = 90

    initialize: ->
      Docyt.vent.on('client:created', @addClient)
      @currentPage = 1

    onShow: ->
      @setHighlightTab()
      @setupDragAndDrop()
      $(window).on( "scroll", @bottomHandler )

    onDestroy: ->
      @removeDragAndDropEventListeners()
      Docyt.vent.off('client:created')
      $(window).off( "scroll", @bottomHandler )

    addClient: (client) =>
      @collection.unshift(client)

    removeDragAndDropEventListeners: ->
      @htmlBody.off('dragover')
      @htmlBody.off('drop')

    setupDragAndDrop: ->
      # Optimization: save DOM elements to reuse them instead of searching for them each time
      @htmlBody = $('body')

      # events to listen to for drag'n'drop
      @htmlBody.on('dragover', @highlightEachClientDropzone)
      @htmlBody.on('drop', @drop)

    highlightEachClientDropzone: (e) ->
      e.preventDefault()
      Docyt.vent.trigger('clients:list:highlight')

    drop: (e) =>
      e.preventDefault()
      e.stopPropagation()
      Docyt.vent.trigger('clients:list:highlight:remove')
      e.originalEvent.dataTransfer.dropEffect = 'copy'
      files = new Docyt.Services.DragAndDropFileUploadHelper(e).getFilesFromEvent()
      modalView = new Docyt.AdvisorHomeApp.Shared.DocumentsUploadModalNoClientView
        files: files
        clients: @collection.models

      Docyt.modalRegion.show(modalView)

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('#clients_tab').addClass('header__nav-item--active')

    bottomHandler: =>
      bodyHeight      = $('body').height()
      heightOfWindow  = window.innerHeight
      contentScrolled = window.pageYOffset

      total = bodyHeight - heightOfWindow
      resultPercentage = parseInt(contentScrolled / total * 100)

      if resultPercentage >= PERCENT_FROM_TOP && @currentPage < @options.pagesCount
        @loadClients()

    loadClients: =>
      $(window).off( "scroll", @bottomHandler )
      Docyt.vent.trigger('show:spinner')
      @currentPage += 1
      clients = new Docyt.Entities.Clients()

      clients.fetch(data: { page: @currentPage }).success (response) =>
        @options.pagesCount = response.meta.pages_count
        @collection.push(response.clients)
        $(window).on( "scroll", @bottomHandler )
        Docyt.vent.trigger('hide:spinner')
      .error =>
        $(window).on( "scroll", @bottomHandler )
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Unable to load clients. Try later.', 'Something went wrong!')
