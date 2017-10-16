@Docyt.module "SignUpApp.ConfirmPhone", (ConfirmPhone, App, Backbone, Marionette, $, _) ->

  class ConfirmPhone.ConfirmPhoneNumber extends Marionette.ItemView
    template:  'sign_up/confirm_phone/confirm_phone_tmpl'

    ui:
      codeInput:  '#confirmation-code'
      submitCode: '#submit-code'
      resendCode: '.resend-code-js'
      confirmationForm: '#confirmation-form'

      # validation messages
      invalidCode: '#invalid-code'

    events:
      'click @ui.resendCode': 'resendCode'
      'click @ui.submitCode': 'submitCode'
      'submit @ui.confirmationForm': 'submitCode'

    onShow: ->
      @ui.codeInput.focus()

    submitCode: (e) ->
      e.preventDefault()
      return unless @ui.codeInput.val().length > 0

      params =
        token: @ui.codeInput.val()

      if Docyt.currentAdvisor.get('web_app_is_set_up')
        @phoneConfirmation(params)
      else
        @webPhoneConfirmation(params)

    webPhoneConfirmation: (params) ->
      params.type = 'web'
      Docyt.currentAdvisor.save(params, url: '/api/web/v1/advisor/confirm_phone_number').success =>
        Docyt.currentAdvisor.unset('token')
        Backbone.history.navigate("/sign_up/confirm_pincode", { trigger: true })
      .error =>
        @ui.invalidCode.show()

    phoneConfirmation: (params) ->
      $.ajax
        method: 'PUT'
        url: '/api/web/v1/advisor/confirm_phone_number'
        contentType: "application/json",
        dataType: "json"
        data: JSON.stringify(params)
        beforeSend: (xhr) ->
          xhr.setRequestHeader('X-User-Token', localStorage["auth_token"])
        success: (response, status) =>
          @model.set('phone_confirmed_at', response.advisor.phone_confirmed_at)
          Backbone.history.navigate("/clients", { trigger: true })
        error: (response, status) =>
          if response.status == 401
            Backbone.history.navigate("/sign_in", { trigger: true })
          else
            @ui.invalidCode.show()

    resendCode: ->
      Docyt.currentAdvisor.fetch(
        url: '/api/web/v1/advisor/send_phone_token',
        data: { user_id: Docyt.currentAdvisor.id, resend_code: true }
      ).done =>
        toastr.success('Confirmation code was sent to your phone number', 'Success.')
