@Docyt.module "AdvisorHomeApp.Messaging.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.MessagingHeaderItem extends Marionette.ItemView
    template: 'advisor_home/messaging/show/messaging_header_item_tmpl'

    SEARCH_DEBOUNCE_INTERVAL = 500

    ui:
      searchField:     '.clients__search-input'
      progressBar:     '.progress-bar'
      progressBlock:   '.progress'
      clearSearchIcon: '.clients__search-clear'

    events:
      'keyup @ui.searchField' :    'onQueryChanged'
      'click @ui.clearSearchIcon': 'clearInput'

    onQueryChanged: _.debounce(
      -> @startSearch()
      SEARCH_DEBOUNCE_INTERVAL
    )

    initialize: ->
      Docyt.vent.on('progress:bar:header', @updateProgress)
      Docyt.vent.on('cancel:upload:document', @hideProgressBar)

    onDestroy: ->
      Docyt.vent.off('progress:bar:header')
      Docyt.vent.off('cancel:upload:document')

    templateHelpers: ->
      chatMembers: @options.chatMembers.models

    updateProgress: (percentage, fileSize) =>
      @ui.progressBlock.show()
      @ui.progressBar.width("#{percentage}%")
      @ui.progressBar.text("#{percentage}% of #{filesize(fileSize)}")
      @hideProgressBar() if percentage == 100

    hideProgressBar: =>
      @ui.progressBar.width("0%")
      @ui.progressBlock.hide()

    startSearch: ->
      if @options.chatInfo.chat_messages_count > 0 && $.trim(@ui.searchField.val()).length > 0
        @ui.clearSearchIcon.show()
        Docyt.vent.trigger('show:spinner')

        searchData =
          chat_id:       @options.chat.get('id')
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
        data: { chat_id: @options.chat.get('id') }
      ).success =>
        Docyt.vent.trigger('hide:spinner')
        Docyt.vent.trigger('show:found:messages')
        $('.groups-messages-list').unhighlight()
      .error =>
        Docyt.vent.trigger('hide:spinner')
        toastr.error('Load failed. Please try again.', 'Something went wrong!')
