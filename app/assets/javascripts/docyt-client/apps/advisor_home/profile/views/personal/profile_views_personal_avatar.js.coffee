@Docyt.module 'AdvisorHomeApp.Profile.Views.Personal', (Personal, App, Backbone, Marionette, $, _) ->

  class Personal.Avatar extends Marionette.ItemView
    template: 'advisor_home/profile/views/personal/avatar_view_tmpl'

    ui:
      avatar:       '#personal-avatar'
      editButton:   '#personal-avatar-edit-btn'
      cancelButton: '#personal-avatar-cancel-btn'
      error:        '#avatar-invalid-error'

    events:
      'click @ui.editButton':   'setupDragAndDrop'
      'click @ui.cancelButton': 'removeDragAndDropEventListeners'

    templateHelpers: ->
      avatarUrl: @model.getAdvisorAvatarUrl()

    initialize: ->
      # Optimization: save DOM elements to reuse them instead of searching for them each time
      @htmlBody = $('body')
      Docyt.vent.on('avatar:upload:success', @avatarUploaded)

    onDestroy: ->
      @removeDragAndDropEventListeners()
      Docyt.vent.off('avatar:upload:success')

    setupDragAndDrop: ->
      @htmlBody.on('dragover', @highlightClientDropzone)
      @htmlBody.on('drop', @drop)
      @htmlBody.on('dragleave', @dragleave)
      @htmlBody.on('dragenter', @dragenter)
      @ui.error.hide()

    removeDragAndDropEventListeners: ->
      @htmlBody.off('dragover')
      @htmlBody.off('drop')
      @htmlBody.off('dragleave')
      @htmlBody.off('dragenter')

    highlightClientDropzone: (e) =>
      e.preventDefault()
      @ui.avatar.addClass('drop__zone_active')

    hideClientDropzone: (e) =>
      e.preventDefault()
      @ui.avatar.removeClass('drop__zone_active')

    drop: (e) =>
      e.preventDefault()
      e.originalEvent.dataTransfer.dropEffect = 'copy'
      file = new Docyt.Services.DragAndDropFileUploadHelper(e).getFirstFileFromEvent()
      @hideClientDropzone(e)

      uploader = new Docyt.Services.UploadAvatarToS3Service(file, @model.get('id'))

      if uploader.isValid()
        uploader.upload()
      else
        @ui.error.show()

    dragleave: (e) =>
      @hideClientDropzone(e) if @dragZoneLeft
      @dragZoneLeft = true

    dragenter: =>
      @dragZoneLeft = false

    avatarUploaded: =>
      @model.fetch().success (response) =>
        @model.updateSelf(response.advisor)
        @removeDragAndDropEventListeners()
        @render()
