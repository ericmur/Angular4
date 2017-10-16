@Docyt.module "Services", (Services, App, Backbone, Marionette, $, _) ->

  class Services.UploadToS3Service extends Marionette.Object

    initialize: (data = {}) ->
      @files    = data.files
      @client   = data.client
      @contact  = data.contact
      @business = data.business

      @temporary   = data.temporary
      @chatMembers = data.chatMembers

      @filesCollection = data.filesCollection
      Docyt.vent.on('cancel:uploading:to:s3', @cancelUploading)

    onDestroy: ->
      Docyt.vent.off('cancel:uploading:to:s3')

    generate_key_for_s3: (document) ->
      "#{document.id}-#{document.original_file_name}"

    upload: ->
      for file in @filesCollection.models
        @baseUpload(file)

    uploadSingleFile: (file) ->
      @baseUpload(file)

    baseUpload: (file) =>
      file = @setFileParams(file)

      file.save().done (response) =>
        file.set(response.document)

        Docyt.vent.trigger('set:document:id:messages:page', file: response.document)

        AWS.config.update(region: configData.cognitoRegion)
        AWS.config.credentials = new AWS.CognitoIdentityCredentials(IdentityPoolId: configData.cognitoPoolId)

        AWS.config.credentials.get( =>
          AWS.config.update(region: configData.bucketRegion)

          bucket = @setAwsS3Config(response.document.symmetric_key.key)

          fileToUpload = _.find(@files, { name: response.document.original_file_name } )

          @uploadFileToS3(file, fileToUpload, bucket, response.document) if fileToUpload
        )

    setAwsS3Config: (documentSymKey) ->
      bucket = new AWS.S3(
        params:
          region: configData.bucketRegion
          Bucket: configData.bucketName
          SSECustomerKey:       AWS.util.base64.decode(documentSymKey)
          SSECustomerAlgorithm: configData.encryptionAlgorithm
        config:
          signatureVersion: 'v4'
      )

    uploadFileToS3: (file, fileToUpload, bucket, document) ->
      s3_object_key = @generate_key_for_s3(document)

      @request = bucket.upload(@setS3ObjectParams(s3_object_key, fileToUpload), (err, data) =>
        if err
          Docyt.vent.trigger('file:upload:fail')
        else
          s3ObjectKey = data.Key || data.key # for multipart upload compatibility as it returns Key, not key

          file.set(final_file_key: s3ObjectKey, s3_object_key:  s3ObjectKey)

          @updateS3Key(file, document.id)
      )
      Docyt.vent.trigger('file:upload:started', fileToUpload, document)

      @request.on('httpUploadProgress', (progress) ->
        Docyt.vent.trigger('file:upload:progress',
          filename: fileToUpload.name
          progressPercentage: Math.round(progress.loaded/progress.total*100)
        )
      )

    updateS3Key: (file, documentId) ->
      file.completeUpload(documentId).done (response) =>
        contactParams = @setContactParams()

        Docyt.vent.trigger('file:upload:success',
          documentJson: response.document
          clientId:    @client.get('id') if @client
          contactId:   contactParams.contactId
          contactType: contactParams.contactType
        )

    cancelUploading: =>
      @request.abort()

    setFileParams: (file) ->
      return @setChatMemberIds(file) if @temporary

      if @business then @setBusinessParams(file) else @setOwners(file)

    getOwner: ->
      if @contact then @contact else @client

    setOwners: (file) ->
      owner = @getOwner()

      file.set(
        client_id: @client.get('id')
        document_owners: [ owner_id: owner.get('id'), owner_type: owner.get('type')]
      )

    setChatMemberIds: (file) ->
      file.set(
        temporary: @temporary
        chat_members: @chatMembers
      )

    setContactParams: ->
      data =
        contactId:   if @contact then @contact.get('id')   else null
        contactType: if @contact then @contact.get('type') else null

      data

    setBusinessParams: (file) ->
      file.set(business_id: @business.get('id'))

    setS3ObjectParams: (s3ObjectKey, fileToUpload) ->
      data =
        Key:  s3ObjectKey
        Body: fileToUpload
        ContentType: fileToUpload.type

      data
