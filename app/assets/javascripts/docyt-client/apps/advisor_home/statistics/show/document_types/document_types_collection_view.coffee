@Docyt.module "AdvisorHomeApp.Statistics.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.DocumentTypesList extends Marionette.CompositeView
    template: 'advisor_home/statistics/show/document_types/document_types_collection_tmpl'
    childViewContainer: '.categories-list'

    PERCENT_FROM_TOP = 90

    getChildView: ->
      Show.DocumentTypeView

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
        @loadDocumentTypes()

    loadDocumentTypes: =>
      $(window).off( "scroll", @bottomHandler )
      Docyt.vent.trigger('show:spinner')
      @currentPage += 1
      categories = new Docyt.Entities.StandardDocuments

      categories.fetch(data: @setParams()).success (response) =>
        @options.pagesCount = response.meta.pages_count
        @collection.push(response.standard_documents)
        $(window).on( "scroll", @bottomHandler )
        Docyt.vent.trigger('hide:spinner')
      .error =>
        $(window).on( "scroll", @bottomHandler )
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Unable to load clients. Try later.', 'Something went wrong!')

    setParams: ->
      data =
        page:        @currentPage
        per_page:    100
        for_support: true

      data
