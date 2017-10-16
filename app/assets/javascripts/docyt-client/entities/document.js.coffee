@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Document extends Backbone.Model
    paramRoot: 'document'
    urlRoot: -> "/api/web/v1/documents"

    parse: (response) ->
      if response.document then response.document else response

    updateCategory: ->
      @save({}, url: "/api/web/v1/documents/#{@get('id')}/update_category")

    fetchForAdvisorViaEmail: ->
      @fetch(url: "/api/web/v1/advisor/documents/#{@get('id')}/document_via_email")

    getEmailBody: ->
      if body_html = @get('email').body_html
        body_html
      else
        body_text = '<p>' + @get('email').body_text + '</p>'

    getIconType: ->
      fileType = @get('file_content_type')

      iconClass = switch
        when fileType == undefined or fileType == null then 'icon-empty-file'
        when fileType == 'application/pdf' then 'icon-pdf-file'
        when fileType.startsWith('image/') then 'icon-photo-file'
        when fileType == "application/vnd.openxmlformats-officedocument.wordprocessingml.document" or \
          fileType.startsWith('application/msword') then 'icon-doc-file'
        when fileType == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" or \
          fileType.startsWith('application/vnd.ms-excel') then 'icon-xls-file'
        else 'icon-empty-file'

    getTruncatedName: (symbolCount) ->
      trimmedName = $.trim(@get('original_file_name'))
      return trimmedName if trimmedName.length < symbolCount
      originalFileName = @get('original_file_name')
      dotIndex = originalFileName.lastIndexOf('.')
      extension = originalFileName.substr(dotIndex + 1)
      filename = originalFileName.substr(0, dotIndex)
      "#{filename.substring(0, symbolCount)} ...#{extension}"

    getDocumentUrl: (client) ->
      clientObject = if client.get('type') == 'Client' then 'clients' else 'contacts'

      "/#{clientObject}/#{client.get('id')}/documents/#{@get('id')}"

    getFileName: ->
      if @get('uploading') || !@has('standard_document_id')
        @get('original_file_name')
      else
        "#{@get('standard_folder_name')}/#{@get('standard_document_name')}"

    getFileInfo: ->
      if @has('standard_document_id')
        return 'Access restricted' unless @get('have_access')

        if @get('state') == 'converting'
          @infoForConvertingDoc()
        else
          @infoForConvertedDoc()

      else
        "#{filesize(@get('storage_size'))}"

    getPagesCount: ->
      I18n.t('clients.pages.counter', count: @get('pages_count'))

    infoForConvertedDoc: ->
      "#{@getPagesCount()} Owned By #{@infoAboutOwners()}"

    infoForConvertingDoc: ->
      "Owned By #{@infoAboutOwners()}"

    infoAboutOwners: ->
      cnt = @get('document_owners_count')

      if cnt > 1
        "#{@get('first_document_owner_name')} & #{ cnt - 1} others"
      else
        @get('first_document_owner_name')
