@Docyt.module "AdvisorHomeApp.Contacts.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ContactsList extends Marionette.CollectionView

    PERCENT_FROM_TOP = 90

    initialize: ->
      Docyt.vent.on('client:created', @addCreatedContact)
      @currentPage = 1

    onRender: ->
      @setHighlightTab()
      $(window).off( "scroll", @bottomHandler )
      $(window).on( "scroll", @bottomHandler )

    onDestroy: ->
      Docyt.vent.off('client:created')
      $(window).off( "scroll", @bottomHandler )

    getChildView: ->
      Index.ContactView

    addContact: (contact) =>
      @collection.add(contact)

    setHighlightTab: ->
      $('.header').find('.header__nav-item--active').removeClass('header__nav-item--active')
      $('#contacts_tab').addClass('header__nav-item--active')

    bottomHandler: =>
      bodyHeight      = $('body').height()
      heightOfWindow  = window.innerHeight
      contentScrolled = window.pageYOffset

      total = bodyHeight - heightOfWindow
      resultPercentage = parseInt(contentScrolled / total * 100)

      if resultPercentage >= PERCENT_FROM_TOP && @currentPage < @options.pagesCount
        @loadContacts()

    loadContacts: =>
      $(window).off( "scroll", @bottomHandler )
      Docyt.vent.trigger('show:spinner')
      @currentPage += 1
      contacts = new Docyt.Entities.Contacts

      contacts.fetch(data: { user_id: Docyt.currentAdvisor.get('id'), page: @currentPage }).success (response) =>
        @options.pagesCount = response.meta.pages_count
        @collection.push(response.contacts)
        $(window).on( "scroll", @bottomHandler )
        Docyt.vent.trigger('hide:spinner')
      .error =>
        $(window).on( "scroll", @bottomHandler )
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Unable to load contacts. Try later.', 'Something went wrong.')

    addCreatedContact: (contact) =>
      @collection.reset([contact]) if @collection.where(default: true).length > 0
