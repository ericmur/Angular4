@Docyt.module "Services", (Services, App, Backbone, Marionette, $, _) ->

  class Services.DragAndDropFileUploadHelper extends Marionette.Object
    initialize: (evt) ->
      @evt    = evt
      @errors = []
      @allowedFiles = []

    getFilesFromEvent: (options = {}) ->
      return unless @evt.originalEvent.dataTransfer.files.length

      if options.documentPage
        files = @getOnlyPdfFiles()
      else
        files = @getSpecificFiles()

      files

    getFirstFileFromEvent: ->
      return unless @evt.originalEvent.dataTransfer.files.length

      file = @evt.originalEvent.dataTransfer.files[0]

    getOnlyPdfFiles: ->
      _.each(@evt.originalEvent.dataTransfer.files, (file) =>
        if file.type == 'application/pdf' then @allowedFiles.push(file) else @errors.push('not supported by type')
      )

      toastr.error('Only PDFs are allowed.', 'Upload Error', positionClass: "toast-top-center") if @errors.length > 0

      @allowedFiles

    getSpecificFiles: ->
      _.each(@evt.originalEvent.dataTransfer.files, (file) =>
        switch
          when file.type == 'application/pdf' then @allowedFiles.push(file)
          when file.type.startsWith('image/') then @allowedFiles.push(file)
          when file.type.startsWith('application/msword') then @allowedFiles.push(file)
          when file.type.startsWith('application/vnd.ms-excel') then @allowedFiles.push(file)
          when file.type.startsWith('application/vnd.ms-powerpoint') then @allowedFiles.push(file)
          when file.type.startsWith('application/vnd.openxmlformats-officedocument') then @allowedFiles.push(file)
          else @errors.push('not supported type')
      )

      if @errors.length > 0
        toastr.error(
          'You can only save files in one of these formats in Docyt: pdf, image, Word, Excel and PowerPoint.',
          'Upload Error',
          positionClass: "toast-top-center"
        )

      @allowedFiles
