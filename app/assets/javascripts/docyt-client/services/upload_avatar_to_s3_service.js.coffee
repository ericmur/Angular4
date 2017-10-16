@Docyt.module "Services", (Services, App, Backbone, Marionette, $, _) ->

  class Services.UploadAvatarToS3Service extends Marionette.Object

    ALLOWED_IMAGE_TYPES = /(png|jpg|jpeg)/

    initialize: (avatarFile, advisorId, avatarType) ->
      @avatar = new Docyt.Entities.Avatar(advisor_id: advisorId)
      @file = avatarFile
      @type = avatarType

    isValid: ->
      @file.type && @file.type.match(ALLOWED_IMAGE_TYPES)

    generate_key_for_s3: (avatarId, fileName) ->
      "avatar-#{avatarId}-#{fileName}"

    upload: ->
      @avatar.save({ avatar_type:  @type }).done (response) =>
        @avatar.set(response.avatar)
        AWS.config.update({ region: configData.cognitoRegion })
        AWS.config.credentials = new AWS.CognitoIdentityCredentials({
          IdentityPoolId: configData.cognitoPoolId
        })

        AWS.config.credentials.get( =>
          AWS.config.update({ region: configData.bucketRegion })

          bucket = new AWS.S3(params:
            region: configData.bucketRegion
            Bucket: configData.bucketName
          )
          bucket.config.signatureVersion = 'v4'

          if @file
            s3_object_key = @generate_key_for_s3(response.avatar.id, @file.name)
            params =
              ACL: 'public-read'
              Key: s3_object_key
              ContentType: @file.type
              Body: @file

            request = bucket.upload(params, (err, data) =>
              if err
                Docyt.vent.trigger('file:upload:fail')
              else
                s3ObjectKey = data.Key || data.key # for multipart upload compatibility as it returns Key, not key

                @avatar.save({ avatar: { s3_object_key:  s3ObjectKey }},
                  url: "/api/web/v1/advisor/#{@avatar.get('advisor_id')}/avatar/complete_upload"
                ).done () =>
                  Docyt.vent.trigger('avatar:upload:success')
            )
        )
