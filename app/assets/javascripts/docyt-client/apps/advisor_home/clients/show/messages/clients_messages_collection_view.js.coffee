@Docyt.module "AdvisorHomeApp.Clients.Show.Messages", (Messages, App, Backbone, Marionette, $, _) ->

  class Messages.MessagesList extends Marionette.CompositeView
    template: 'advisor_home/clients/show/messages/clients_messages_list_tmpl'

    ui:
      collapsedItem: '.client__mes-panel-title'

    events:
      'click @ui.collapsedItem': 'scrollToBottom'

    getChildView: (item) ->
      itemDateCreated = moment(item.get('created_at')).format('MMMM YYYY')
      if itemDateCreated == @model.get('date') && (item.has('uploading') || item.has('chat_document'))
        Messages.ChatMessageUploadDocumentItemView
      else
        Messages.ChatMessageItemView

    templateHelpers: ->
      monthGroup: @model.get('date')
      uniqId: @model.cid

    onShow: ->
      @scrollToBottom()

    attachBuffer: (collectionView, buffer) ->
      collectionView.$el.find('.client__mes-panel-body').append(buffer)

    attachHtml: (collectionView, childView, index) ->
      if @model.get('date') == moment(childView.model.get('created_at')).format('MMMM YYYY')
        @addMessage(collectionView, childView)
      else
        @addCurrentMonthBlock(collectionView, childView)

    addCurrentMonthBlock: (collectionView, childView) =>
      lastDate = @options.dates.last().get('date')
      currentDate = moment(new Date()).format('MMMM YYYY')
      messageCreated = moment(childView.model.get('created_at')).format('MMMM YYYY')
      dateArray = _.map(@options.dates.models, (date) -> date.get('date'))

      if currentDate == messageCreated && lastDate != messageCreated
        @options.dates.add(new Backbone.Model({ date: messageCreated }))
      else if !_.include(dateArray, messageCreated)
        @options.dates.unshift(new Backbone.Model({ date: messageCreated }))

    onAddChild: (childView) ->
      unless childView.model.get('fromThePast')
        $('.messages-region').mCustomScrollbar("scrollTo", 'bottom', { timeout: 100 })

    scrollToBottom: ->
      $('.messages-region').mCustomScrollbar("scrollTo", 'bottom', { timeout: 100 })

    initCustomScrollbar: ->
      $('.messages-region').mCustomScrollbar
        theme: 'minimal-dark'
        scrollInertia: 100

    addMessage: (collectionView, childView) ->
      if childView.model.get('fromThePast')
        collectionView.$el.find('.client__mes-panel-body').prepend(childView.el)
      else
        collectionView.$el.find('.client__mes-panel-body').append(childView.el)
