@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.HeaderMenu extends Marionette.ItemView
    template: 'advisor_home/clients/show/messages/clients_messages_header_menu_tmpl'

    SEARCH_DEBOUNCE_INTERVAL = 500

    ui:
      searchField:     '.clients__search-input'
      progressBar:     '.progress-bar'
      progressBlock:   '.progress'
      documentsCount:  '.documents-count'
      clearSearchIcon: '.clients__search-clear'

    events:
      'keyup @ui.searchField' :    'onQueryChanged'
      'click @ui.clearSearchIcon': 'clearInput'

    onQueryChanged: _.debounce(
      -> @startSearch()
      SEARCH_DEBOUNCE_INTERVAL
    )

    templateHelpers: ->
      documentsCount: @options.chatInfo.chat_docs_count
      chatUsersCount: @options.chatInfo.chat_users_count

    initialize: ->
      Docyt.vent.on('progress:bar:header', @updateProgress)
      Docyt.vent.on('cancel:upload:document', @hideProgressBar)
      Docyt.vent.on('update:documents:count:header', @updateDocumentsCount)

    onDestroy: ->
      Docyt.vent.off('progress:bar:header')
      Docyt.vent.off('cancel:upload:document')
      Docyt.vent.off('update:documents:count:header')

    updateProgress: (percentage, fileSize) =>
      @ui.progressBlock.show()
      @ui.progressBar.width("#{percentage}%")
      @ui.progressBar.text("#{percentage}% of #{filesize(fileSize)}")
      @hideProgressBar() if percentage == 100

    updateDocumentsCount: (data) =>
      event = data.event
      switch event
        when 'addDocument'
          @ui.documentsCount.text("#{@options.chatInfo.chat_docs_count += 1} Documents")
        when 'deleteDocument'
          @ui.documentsCount.text("#{@options.chatInfo.chat_docs_count -= 1} Documents")

    hideProgressBar: =>
      @ui.progressBar.width("0%")
      @ui.progressBlock.hide()

    startSearch: ->
      if @options.chatInfo.chat_messages_count > 0 && $.trim(@ui.searchField.val()).length > 0
        @ui.clearSearchIcon.show()
        Docyt.vent.trigger('show:spinner')

        searchData =
          chat_id:       @options.chatId
          search_phrase: @ui.searchField.val().replace(/[^a-zA-Z0-9_]+/, '')

        @getSearchResult(searchData)

      else
        Docyt.vent.trigger('show:spinner')
        @getDefaultMessages()
        @ui.clearSearchIcon.hide()

    clearInput: ->
      @ui.searchField.val('')
      @startSearch()

    getSearchResult:(searchData) =>
      @options.messages.fetch(
        url: "/api/web/v1/messages/search"
        data: searchData
      ).success =>
        Docyt.vent.trigger('hide:spinner')
        Docyt.vent.trigger('show:found:messages')
        $('.groups-messages-list').highlight(searchData.search_phrase)
      .error =>
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Search failed. Please try again.', 'Something went wrong!')

    getDefaultMessages: ->
      @options.messages.fetch(
        url: "/api/web/v1/messages"
        data: { chat_id: @options.chatId }
      ).success =>
        Docyt.vent.trigger('hide:spinner')
        Docyt.vent.trigger('show:found:messages')
        $('.groups-messages-list').unhighlight()
      .error =>
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Load failed. Please try again.', 'Something went wrong!')
