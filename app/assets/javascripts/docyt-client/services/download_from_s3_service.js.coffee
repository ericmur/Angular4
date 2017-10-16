@Docyt.module "Services", (Services, App, Backbone, Marionette, $, _) ->

  class Services.DownloadFromS3 extends Marionette.Object

    initialize: (options) ->
      @triggerName       = options.trigger_name || 'file:download:success'
      @symmetric_key     = options.symmetric_key
      @bucket_object_key = options.s3_key

    download: ->
      AWS.config.update({ region: configData.cognitoRegion })
      AWS.config.credentials = new AWS.CognitoIdentityCredentials({
        IdentityPoolId: configData.cognitoPoolId
      })

      AWS.config.credentials.get( =>
        AWS.config.update({ region: configData.bucketRegion })
        bucket = new AWS.S3()
        params =
          Key:    @bucket_object_key
          Bucket: configData.bucketName

        if @symmetric_key && @symmetric_key.key
          params.SSECustomerAlgorithm = configData.encryptionAlgorithm
          params.SSECustomerKey       = AWS.util.base64.decode(@symmetric_key.key)

        request = bucket.getObject(params, (err, data) =>
          unless err
            Docyt.vent.trigger(@triggerName, data.Body, @bucket_object_key)
        )

        if @triggerName == 'url:created'
          request.on('httpDownloadProgress', (progress) =>
            Docyt.vent.trigger('message:item:download:progress:bar',
              s3Key: @bucket_object_key
              percentage: Math.round(progress.loaded/progress.total*100)
            )
          )
      )
