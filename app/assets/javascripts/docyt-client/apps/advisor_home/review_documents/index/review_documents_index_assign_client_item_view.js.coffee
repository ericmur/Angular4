@Docyt.module "AdvisorHomeApp.ReviewDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.AssignClientItemView extends Marionette.CompositeView
    className: 'docs-item'
    tagName:  'tr'
    template: 'advisor_home/review_documents/index/review_documents_index_assign_client_item_tmpl'

    ui:
      collapseExpandBtn: ".collapse-expand-btn"
      spinner:           ".fa-spinner"

    events:
      'click @ui.collapseExpandBtn': 'collapseExpandContacts'

    initialize: ->
      @contactsLoaded = false
      Docyt.vent.on("client:selected", @onSelect)

    onDestroy: ->
      Docyt.vent.off("client:selected")

    onSelect: (clientId) =>
      if clientId == @model.id
        @.$el.addClass('selected-assign-client')
      else
        @.$el.removeClass('selected-assign-client')

    onShow: ->
      @ui.spinner.hide()

    attributes: -> 'data-id': @model.id

    showOrHideExpandIcon: ->
      count = 0
      count += @model.get('employees_count') if @model.get('employees_count')
      count += @model.get('contacts_count') if @model.get('contacts_count')
      count += @model.get('contractors_count') if @model.get('contractors_count')
      return 'hide-expand-icon' if count == 0

    collapseExpandContacts: (event) ->
      event.stopPropagation()
      return @collapseContacts() if @ui.collapseExpandBtn.hasClass('expanded')
      @expandContacts()

    expandContacts: ->
      return @openLoadedContacts() if @contactsLoaded
      contacts = @getContacts()
      @showSpinner()
      contacts.fetch(data: { client_id: clientId }).done =>
        @markContactsAsNested(contacts)
        @collection = contacts
        @model.contacts = contacts
        @render()
        @setIcon(true)
        @contactsLoaded = true
      .always =>
        @hideSpinner()

    closeLoadedContacts: ->
      @setIcon(false)
      @nestedContacts.hide()

    openLoadedContacts: ->
      @setIcon(true)
      @nestedContacts.show()

    collapseContacts: ->
      @closeLoadedContacts()

    markContactsAsNested: (contacts) ->
      for contact in contacts.models
        contact.set('nestedClass', 'nested')
        contact.set('isNested', true)

    setIcon: (condition) ->
      @ui.collapseExpandBtn.toggleClass('expanded')
      if condition
        @toggleIcon('collapse-ico', 'expand-ico')
      else
        @toggleIcon('expand-ico', 'collapse-ico')

    toggleIcon: (add, remove) ->
      @ui.collapseExpandBtn.removeClass(remove)
      @ui.collapseExpandBtn.addClass(add)

    getContacts: ->
      new Docyt.Entities.Contacts()

    templateHelpers: ->
      avatarUrl: @getClientAvatarUrl()
      showOrHideExpandIcon: @showOrHideExpandIcon()

    onSelectClient: ->
      @.$el.addClass('selected-assign-client')

    onUnselectClient: ->
      @.$el.removeClass('selected-assign-client')

    getClientAvatarUrl: ->
      return unless @model.has('avatar')
      s3_object_key = @model.get('avatar').s3_object_key
      "https://#{configData.bucketName}.s3.amazonaws.com/#{s3_object_key}"

    attachHtml: (collectionView, itemView) ->
      id = "nested-#{collectionView.$el.data('id')}"
      selector = "##{id}"

      itemView.$el.addClass('nested')
      if collectionView.$el.next(selector).length == 0
        collectionView.$el.after("<div id=#{id} data-id=\"#{collectionView.$el.data('id')}\" class=\"nested-wrapper\"></div>")
      collectionView.$el.next(selector).append(itemView.el)
      @nestedContacts = collectionView.$el.next(selector).first()

    showSpinner: ->
      @ui.spinner.show()
      @ui.collapseExpandBtn.removeClass('expand-ico')

    hideSpinner: ->
      @ui.spinner.hide()
