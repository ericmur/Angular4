@Docyt.module "AdvisorHomeApp.Shared", (Shared, App, Backbone, Marionette, $, _) ->

  class Shared.FileUploadItemView extends Marionette.ItemView
    template: 'advisor_home/clients/shared/file_upload_item_view_tmpl'

    ui:
      progressBar:        '.file-status-line'
      progressBarWrapper: '.upload-file-status'
      fileTypeIcon:       '#file-icon'

    initialize: ->
      Docyt.vent.on('file:upload:progress', @updateProgress)

    onRender: ->
      @setFileIcon()

    onDestroy: ->
      Docyt.vent.off('file:upload:progress')

    templateHelpers: ->
      fileSize: filesize(@model.get('storage_size'))

    updateProgress: (progress) =>
      if progress.filename == @model.get('original_file_name')
        @ui.progressBar.width("#{progress.progressPercentage}%")

        if progress.progressPercentage == 100
          @._parent.trigger('file:uploaded')
          @ui.progressBarWrapper.addClass('upload-done')

    setFileIcon: ->
      @ui.fileTypeIcon.addClass(@model.getIconType())
