@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.File extends Backbone.Model
    paramRoot: 'document'
    urlRoot: -> "/api/web/v1/documents"

    completeUpload: (documentId) ->
      @save({}, url: "/api/web/v1/documents/#{documentId}/complete_upload")

    getIconType: ->
      fileType = @get('file_content_type')

      iconClass = switch
        when fileType == undefined or fileType == null then 'icon-empty-file'
        when fileType == 'application/pdf' then 'icon-pdf-file'
        when fileType.startsWith('image/') then 'icon-photo-file'
        when fileType.startsWith('application/vnd.ms-word') then 'icon-doc-file'
        when fileType.startsWith('application/application/vnd.openxmlformats-officedocument') or \
          fileType.startsWith('application/vnd.ms-word') then 'icon-doc-file'
        when fileType.startsWith('application/vnd.ms-excel') then 'icon-xls-file'
        else 'icon-empty-file'
