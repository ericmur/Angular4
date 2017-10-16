@Docyt.module "SignUpApp.AddPhone", (AddPhone, App, Backbone, Marionette, $, _) ->

  class AddPhone.AddPhoneNumber extends Marionette.ItemView
    template:  'sign_up/add_phone/add_phone_tmpl'

    ui:
      phoneInput:   '#phone-number'
      submitPhone:  '#submit-phone'
      addPhoneForm: '#add-phone-form'

      # validation messages
      invalidPhone: '#invalid-phone'

    events:
      'click @ui.submitPhone':   'submitPhone'
      'submit @ui.addPhoneForm': 'submitPhone'

    onShow: ->
      @ui.phoneInput.focus()

    submitPhone: (e) ->
      e.preventDefault()

      params =
        phone:    @ui.phoneInput.val()

      $.ajax
        method: 'POST'
        url: '/api/web/v1/advisor/add_phone_number'
        contentType: "application/json",
        dataType: "json"
        data: JSON.stringify(params)
        beforeSend: (xhr) ->
          xhr.setRequestHeader('X-User-Token', localStorage["auth_token"])
        success: (response, status) ->
          Docyt.currentAdvisor.updateSelf(response.advisor)
          Backbone.history.navigate("/sign_up/confirm_phone", { trigger: true })
        error: (response, status) =>
          if response.status == 401
            Backbone.history.navigate("/sign_in", { trigger: true })
          else
            @ui.invalidPhone.show()
