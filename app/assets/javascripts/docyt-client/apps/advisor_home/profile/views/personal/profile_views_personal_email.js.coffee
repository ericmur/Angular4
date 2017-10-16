@Docyt.module 'AdvisorHomeApp.Profile.Views.Personal', (Personal, App, Backbone, Marionette, $, _) ->

  class Personal.Email extends Marionette.ItemView
    template: 'advisor_home/profile/views/personal/email_view_tmpl'

    ui:
      form:                    '#form-personal-email'
      emailInput:              '#input-personal-email'
      submitButton:            '#submit-personal-email'
      sendedConfirmEmailAlert: "#sended-confirm-email-alert"

      # validation messages
      emailInvalid: '#email-invalid'
      emailExists:  '#email-exists'

    events:
      'submit @ui.form':        'submitForm'
      'click @ui.submitButton': 'submitForm'

    onShow: ->
      @ui.sendedConfirmEmailAlert.hide()

    submitForm: (e) ->
      e.preventDefault()
      @hideAllErrors()

      error = @model.validateEmail(@ui.emailInput.val())

      if error
        @ui.emailInvalid.show() if _.isString(error)
      else
        @model.set(unverified_email: @ui.emailInput.val())
        @model.updateCurrentAdvisor().error (response) =>
          if response.responseJSON.email
            @ui.emailExists.show()
        .done =>
          @ui.sendedConfirmEmailAlert.show()
          @render()

    hideAllErrors: ->
      @ui.emailInvalid.hide()
      @ui.emailExists.hide()
