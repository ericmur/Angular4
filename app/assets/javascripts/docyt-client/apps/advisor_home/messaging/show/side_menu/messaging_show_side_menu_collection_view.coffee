@Docyt.module "AdvisorHomeApp.Messaging.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.MessagingSideMenuCollection extends Marionette.CompositeView
    template: 'advisor_home/messaging/show/side_menu/messaging_side_menu_collection_tmpl'
    childViewContainer: '.messaging-clients-list'
    className: 'clients-wrap'

    getChildView: ->
      Show.MessagingSideMenuItem

    childViewOptions: ->
      currentChatId: @options.currentChatId

    onShow: ->
      @initCustomScrollbar()

    initCustomScrollbar: ->
      $('.messaging-clients-list').mCustomScrollbar(theme: 'minimal-dark', scrollInertia: 100)
