@Docyt.module "HeaderApp.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.Header extends Marionette.LayoutView
    template: @getTemplate

    regions:
      notificationsRegion: '#header-notifications-region'

    ui:
      signOut:  '.sign-out-js'

      userIcon:             '#user-icon'
      userDropdown:         '#user-dropdown'
      changeWorkspace:      '.change-workspace-js'
      notificationIcon:     '#notification-icon'
      userDropdownLinks:    '#user-dropdown a'
      notificationDropdown: '#notifications-dropdown'
      headerLogo:           '.header__logo'
      selectBiz:            '.header__dropdown-select-biz-js'

    events:
      'click @ui.signOut':           'signOutCurrentAdvisor'
      'click @ui.userIcon':          'toggleUserDropdown'
      'click @ui.changeWorkspace':   'navigatePersonal'
      'click @ui.notificationIcon':  'toggleNotificationsDropdown'
      'click @ui.userDropdownLinks': 'hideAllDropdowns'
      'click @ui.headerLogo':        'navigateHome'
      'click @ui.selectBiz':        'navigateBiz'

    templateHelpers: ->
      myBusiness: Docyt.currentAdvisor.get('businesses')
      avatarUrl: Docyt.currentAdvisor.getAdvisorAvatarUrl()
      isSupport: Docyt.currentAdvisor.get('is_support')

      businesses:    Docyt.currentAdvisor.get('business_names')
      hasBusinesses: Docyt.currentAdvisor.has('business_names')

      isSelectedBiz: @isSelectedBiz

    initialize: ->
      @checkAdvisor()
      Docyt.vent.on('current:advisor:updated', @render)
      Docyt.currentAdvisor.on('change:has_unread_notifications', @hasUnreadNotifications)
      $(document).on('click', @dropdownOuterClick)

    onRender: ->
      @hasUnreadNotifications()

    onDestroy: ->
      Docyt.vent.off('current:advisor:updated')
      $(document).off('click', @dropdownOuterClick)

    isSelectedBiz: (bizId) ->
      if (Docyt.currentAdvisor.get('current_workspace_name') == 'Business' && Docyt.currentAdvisor.get('current_workspace_id') == bizId)
        return 'selected'
      else
        return ''

    navigateHome: (event) ->
      if Docyt.currentAdvisor.isEmpty() || !Docyt.currentAdvisor.get('web_app_is_set_up')
        event.preventDefault()
      else
        Backbone.history.navigate('/select_workspace', trigger: true)

    getTemplate: ->
      if Docyt.currentAdvisor.isEmpty() || !Docyt.currentAdvisor.get('web_app_is_set_up')
        'header/show/header_logged_out_tmpl'
      else
        @getSignedInTemplate()

    signOutCurrentAdvisor: ->
      Docyt.currentAdvisor.signOut()

    toggleNotificationsDropdown: (event) ->
      if @ui.notificationDropdown.hasClass('active-dropdown')
        @ui.notificationDropdown.removeClass('active-dropdown')
      else
        @loadNotifications()
        @hideAllDropdowns()
        @ui.notificationDropdown.addClass('active-dropdown')

    toggleUserDropdown: (event) ->
      if @ui.userDropdown.hasClass('active-dropdown')
        @ui.userDropdown.removeClass('active-dropdown')
      else
        @hideAllDropdowns()
        @ui.userDropdown.addClass('active-dropdown')

    dropdownOuterClick: (event) =>
      return if $(event.target).is("#notifications-dropdown, #notifications-dropdown *") ||
                $(event.target).is("#user-dropdown, #user-dropdown *")
      @hideAllDropdowns()

    hideAllDropdowns: ->
      $('.header__item-wrapper').removeClass('active-dropdown')

    loadNotifications: =>
      notifications = @getNotifications()
      notificationsListView = @getNotificationsView(notifications)
      @notificationsRegion.show(notificationsListView)
      notificationsListView.triggerMethod('showSpinner')

      notifications.fetch().complete ->
        notificationsListView.triggerMethod('hideSpinner')

    getNotifications: ->
      new App.Entities.Notifications()

    getNotificationsView: (notificationsCollection) ->
      new Show.NotificationsList({ collection: notificationsCollection })

    hasUnreadNotifications: =>
      if Docyt.currentAdvisor.get('has_unread_notifications')
        @ui.notificationIcon.addClass('new-notifications')
        @ui.notificationIcon.attr('data-notifications', Docyt.currentAdvisor.get('unread_notifications_count'))
      else
        @ui.notificationIcon.removeClass('new-notifications')
        @ui.notificationIcon.removeAttr('data-notifications')

    checkAdvisor: ->
      return if Docyt.currentAdvisor.isEmpty() || !Docyt.currentAdvisor.get('web_app_is_set_up')

      Docyt.fayeClient.subscribe("/notifications", (data) =>
        Docyt.vent.trigger('update:messages:count', data)
      )

    getSignedInTemplate: ->
      if Docyt.currentAdvisor.get('current_workspace_id')
        @getTemplateForCurrentWorkspace()
      else
        'header/show/header_logged_in_simple_tmpl'

    getTemplateForCurrentWorkspace: ->
      if @currentWorkspace('Business')
        'header/show/header_business_logged_in_tmpl'
      else
        'header/show/header_individual_logged_in_tmpl'

    currentWorkspace: (type) ->
      Docyt.currentAdvisor.get('current_workspace_name') == type

    navigatePersonal: ->
      accountTypes = new Docyt.Entities.ConsumerAccountTypes
      accountTypes.fetch().done =>
        @setPersonalWorkspace(accountTypes)
        Docyt.currentAdvisor.updateCurrentAdvisor().done =>
          @navigateAdvisor()

    setPersonalWorkspace: (accountTypes) ->
      if @currentWorkspace('Business')
        @setAdvisorWorkspace(accountTypes.getType('Family'))

    setAdvisorWorkspace: (type) ->
      Docyt.currentAdvisor.set(
        current_workspace_id: type.get('id')
        current_workspace_name: type.get('display_name')
      )

    navigateAdvisor: ->
      if @currentWorkspace('Business')
        bizId = Docyt.currentAdvisor.get('current_workspace_id')
        Backbone.history.navigate('/businesses/' + bizId + '/standard_folders', trigger: true)
      else
        Backbone.history.navigate('/my_documents', trigger: true)

    navigateBiz: (e) ->
      bizId = $(e.currentTarget).attr("biz-id")
      accountTypes = new Docyt.Entities.ConsumerAccountTypes
      accountTypes.fetch(url: '/api/web/v1/consumer_account_types').done =>
        Docyt.currentAdvisor.set(
          'current_workspace_id': bizId,
          'current_workspace_name': 'Business'
        )
        Docyt.currentAdvisor.updateCurrentAdvisor().done =>
          Backbone.history.navigate('/businesses/' + bizId + '/standard_folders', trigger: true)
