@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.DocumentView extends Marionette.ItemView
    className: 'pdf-iframe-wrapper'
    template: 'advisor_home/clients/show/documents/show/client_document_view_tmpl'

    ui:
      pdfViewerFrame: '#pdf-viewer'

    onShow: ->
      @startDocumentDownload()

    onDestroy: ->
      Docyt.vent.off('file:download:success')

    startDocumentDownload: ->
      # download is async, so we listen for this event to return us a downloaded file
      Docyt.vent.on('file:download:success', @renderPdf)

      downloadService = new Docyt.Services.DownloadFromS3(
        s3_key: @model.get('final_file_key')
        symmetric_key: @model.attributes.symmetric_key
      )
      downloadService.download()

    renderPdf: (uint8DataArray) =>
      @ui.pdfViewerFrame[0].contentWindow.PDFViewerApplication.open(uint8DataArray)
