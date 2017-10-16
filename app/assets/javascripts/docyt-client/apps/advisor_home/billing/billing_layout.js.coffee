@Docyt.module "AdvisorHomeApp.Billing", (Billing, App, Backbone, Marionette, $, _) ->

  class Billing.Layout extends Marionette.LayoutView
    template:  'advisor_home/billing/billing_layout_tmpl'

    regions:
      profileHeaderRegion:    '#advisor-header-region'
      billingSubscriptionRegion:  '#billing-subscription-region'
      profilePersonalRegion:  '#billing-personal-region'

    onRender: ->
      @setHighlightTab()

    onShow: ->
      @removeWrap()

    onDestroy: ->
      @removeHighlightTab()

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('.header__userpic').addClass('highlight-tab')
      $('.header__dropdown-menu').find('a').removeClass('selected')
      $('.billing-link').addClass('selected')

    removeHighlightTab: ->
      $('.header__userpic').removeClass('highlight-tab')
      $('.billing-link').removeClass('selected')

    removeWrap: ->
      $('.client__settings-page').css 'min-height', $(document).height() - $('#header-region').height()
