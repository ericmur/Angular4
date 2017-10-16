@Docyt.module "AdvisorHomeApp.Messaging.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.MessagingLayout extends Marionette.LayoutView
    className: 'messaging__wrap'
    template:  'advisor_home/messaging/show/messaging_layout_tmpl'

    regions:
      chatRegion:      '#chat-region'
      sideMenuRegion:  '#messaging-side-menu-region'
      rightSideRegion: '#messaging-document-right-side-region'

    onRender: ->
      $('body').addClass('two-column')
      @setHighlightTab()

    onDestroy: ->
      $('body').removeClass('two-column')
      $('#messaging-tab').removeClass('highlight-tab')

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('#messaging-tab').addClass('highlight-tab')
