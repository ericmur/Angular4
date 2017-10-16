@Docyt.module "AdvisorHomeApp.LatestDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.DocumentsList extends Marionette.CompositeView
    template: 'advisor_home/latest_documents/index/documents/latest_documents_index_document_collection_tmpl'
    childViewContainer: '.latest-documents-list'

    PERCENT_FROM_TOP = 90

    getChildView: ->
      Index.DocumentItemView

    initialize: ->
      @currentPage = 1

    onRender: ->
      $(window).on( "scroll", @bottomHandler )

    onDestroy: ->
      $(window).off( "scroll", @bottomHandler )

    bottomHandler: =>
      bodyHeight      = $('body').height()
      heightOfWindow  = window.innerHeight
      contentScrolled = window.pageYOffset

      total = bodyHeight - heightOfWindow
      resultPercentage = parseInt(contentScrolled / total * 100)

      if resultPercentage >= PERCENT_FROM_TOP && @currentPage < @options.pagesCount
        @loadDocuments()

    loadDocuments: =>
      $(window).off( "scroll", @bottomHandler )
      Docyt.vent.trigger('show:spinner')
      @currentPage += 1
      documents = new Docyt.Entities.Documents

      documents.fetch(data: @setDocumentsParams()).success (response) =>
        @options.pagesCount = response.meta.pages_count
        @collection.push(response.documents)
        $(window).on( "scroll", @bottomHandler )
        Docyt.vent.trigger('hide:spinner')
      .error =>
        $(window).on( "scroll", @bottomHandler )
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Unable to load documents. Try again later.', 'Something went wrong!')

    setDocumentsParams: ->
      data =
        page:     @currentPage
        per_page: 100
        for_support: true
        only_categorized: true

      data
