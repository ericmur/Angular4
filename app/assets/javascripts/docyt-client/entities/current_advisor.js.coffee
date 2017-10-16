@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.CurrentAdvisor extends Backbone.Model
    url: -> '/api/web/v1/advisor/current_advisor'
    paramRoot: 'advisor'

    EMAIL_REGEXP  = /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,})+$/
    MIN_PASSWORD_LENGTH = 8

    updateCurrentAdvisor: ->
      @save({},
        url: "/api/web/v1/advisor/#{@get('id')}"
        success: (response) =>
          @updateSelf(response)
      )

    parse: (response) ->
      response.advisor

    updateSelf: (advisor_params) =>
      token = advisor_params.authentication_token || (typeof advisor_params.get != "undefined" && advisor_params.get('authentication_token'))
      advisorData = advisor_params.attributes || advisor_params
      localStorage.setItem('auth_token', token)
      @set(advisorData)
      Docyt.setup()
      Docyt.vent.trigger('current:advisor:updated')

    confirmPhoneNumber: ->
      @save({}, url: '/api/web/v1/advisor/confirm_phone_number')

    signOut: ->
      @destroy(
        url: '/api/web/v1/sign_out'
        success: ->
          Docyt.currentAdvisor.clear()
          localStorage.removeItem('auth_token')
          Docyt.vent.trigger('current:advisor:updated')
          Backbone.history.navigate("/sign_in", { trigger: true })
      )

    getAdvisorAvatarUrl: ->
      return unless Docyt.currentAdvisor.has('avatar')
      s3_object_key = Docyt.currentAdvisor.get('avatar').s3_object_key
      "https://#{configData.bucketName}.s3.amazonaws.com/#{s3_object_key}"

    getAmazonS3Url: ->
      "https://#{configData.bucketName}.s3.amazonaws.com/"

    validate: (opts ={}) ->
      if opts.initial
        @errors = []
        if @attributes.email || @attributes.email == ''
          result = @validateEmail(@attributes.email)
          @errors.push(result) if result
        if @attributes.password || @attributes.password == ''
          @validatePasswordLength(@attributes.password)
          @validatePasswordConfirmation(@attributes.password, @attributes.password_confirmation)
        @errors

    advisorTypeSelected: ->
      @errors.push('advisor type cannot be empty')

    validateEmail: (email) ->
      'invalid email' unless (EMAIL_REGEXP.test(email))

    validatePasswordLength: (password) ->
      if password.length < MIN_PASSWORD_LENGTH
        @errors.push('please enter more symbols')

    validatePasswordConfirmation: (password, passwordConfirmation) ->
      if password != passwordConfirmation
        @errors.push('please enter correct password')

    getForwardingEmail: ->
      if email = @get('upload_email')
        email
      else
        'No email for forwarding'

    getName: ->
      @get('full_name') || @get('email')

