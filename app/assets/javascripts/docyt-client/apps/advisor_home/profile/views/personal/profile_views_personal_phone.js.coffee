@Docyt.module 'AdvisorHomeApp.Profile.Views.Personal', (Personal, App, Backbone, Marionette, $, _) ->

  class Personal.Phone extends Marionette.ItemView
    template: 'advisor_home/profile/views/personal/phone_view_tmpl'

    ui:
      form:                              '#form-personal-phone'
      phoneInput:                        '#input-personal-phone'
      submitButton:                      '#submit-personal-phone'
      personalPhoneWraper:               '#collapse-edition-personal-phone'
      confirmationCodeForm:              '#form-personal-phone-confirmation-code'
      confirmationCodeInput:             '#input-personal-phone-confirmation-code'
      confirmationCodeSubmit:            '#submit-personal-phone-confirmation-code'
      confirmationCodeWrapper:           '#wrapper-personal-phone-confirmation-code'
      confirmationCodeShowPersonalPhone: '#personal-phone-confirmation-code-help'

      # validation messages
      phoneInvalid:                 '#phone-invalid'
      phoneExists:                  '#phone-exists'
      phoneConfirmationCodeInvalid: '#phone-confirmation-code-invalid'

    events:
      'submit @ui.form':                  'submitForm'
      'click @ui.submitButton':           'submitForm'
      'submit @ui.confirmationCodeForm':  'submitConfirmationCodeForm'
      'click @ui.confirmationCodeSubmit': 'submitConfirmationCodeForm'

    openConfirmationForm: ->
      @cleanConfirmationInput()
      @ui.confirmationCodeShowPersonalPhone.text(@ui.phoneInput.val())
      @ui.personalPhoneWraper.collapse('hide')
      @ui.confirmationCodeWrapper.collapse('show')

    cleanConfirmationInput: ->
      @ui.confirmationCodeInput.val('')

    submitForm: (e) ->
      e.preventDefault()
      @hideAllErrors()
      @showSpinner()

      @model.set(unverified_phone: @ui.phoneInput.val())

      @model.updateCurrentAdvisor().error (response) =>
        @hideSpinner()
        @ui.phoneInvalid.show() if response.responseJSON.unverified_phone
        @ui.phoneExists.show() if response.responseJSON.phone
      .success (response) =>
        @hideSpinner()
        @openConfirmationForm()

    submitConfirmationCodeForm: (e) ->
      e.preventDefault()
      @hideAllErrors()

      @model.set(token: @ui.confirmationCodeInput.val(), change_phone_number: true)

      @model.confirmPhoneNumber().error (response) =>
        @ui.phoneConfirmationCodeInvalid.show() if response.responseJSON.error_message
      .success (response) =>
        @model.set('phone_normalized', response.advisor.phone_normalized)
        @render()

    hideAllErrors: ->
      @ui.phoneInvalid.hide()
      @ui.phoneExists.hide()
      @ui.phoneConfirmationCodeInvalid.hide()

    showSpinner: ->
      $('body').addClass('spinner-open')
      $('body').append("<div class='spinner-overlay'><i class='fa fa-spinner fa-pulse'></i></div>")

    hideSpinner: ->
      $('body').removeClass('spinner-open')
      $('.spinner-overlay').remove()
