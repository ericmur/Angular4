@Docyt.module "AdvisorHomeApp.Clients.Show.Details.Contacts.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.ContactsList extends Marionette.CollectionView

    PERCENT_FROM_TOP = 90

    getChildView: ->
      Index.ContactsItemView

    childViewOptions: ->
      client: @options.client

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

      if resultPercentage >= PERCENT_FROM_TOP && @currentPage < @collection.pagesCount
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
