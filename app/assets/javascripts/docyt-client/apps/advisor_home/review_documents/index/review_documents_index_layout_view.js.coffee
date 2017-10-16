@Docyt.module "AdvisorHomeApp.ReviewDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.Layout extends Marionette.LayoutView
    className: 'docs-wrap'
    template:  'advisor_home/review_documents/index/review_documents_index_layout_tmpl'

    regions:
      headerMenuRegion:    '#documents-review-header-menu-region'
      documentsListRegion: '#documents-review-list-region'
      documentsModalRegion: '#documents-review-modal-region'

    onRender: ->
      $('body').addClass('two-column')
      @setHighlightTab()

    onDestroy: ->
      $('body').removeClass('two-column')
      $('#review-documents-tab').removeClass('highlight-tab')

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('#review-documents-tab').addClass('highlight-tab')
