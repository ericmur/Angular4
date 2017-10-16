@Docyt.module "AdvisorHomeApp.Profile", (Profile, App, Backbone, Marionette, $, _) ->

  class Profile.Layout extends Marionette.LayoutView
    template:  'advisor_home/profile/profile_layout_tmpl'

    regions:
      profileHeaderRegion:    '#advisor-header-region'
      profilePersonalRegion:  '#advisor-personal-region'
      profileBusinessRegion:  '#advisor-business-region'
      profileSecurityRegion:  '#advisor-security-region'

    onRender: ->
      @setHighlightTab()

    onDestroy: ->
      @removeHighlightTab()

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('.header__userpic').addClass('highlight-tab')
      $('.header__dropdown-menu').find('a').removeClass('selected')
      $('.profile-link').addClass('selected')

    removeHighlightTab: ->
      $('.header__userpic').removeClass('highlight-tab')
      $('.profile-link').removeClass('selected')
