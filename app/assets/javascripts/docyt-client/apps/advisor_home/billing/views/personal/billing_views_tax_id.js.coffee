@Docyt.module 'AdvisorHomeApp.Billing.Views.Personal', (Personal, App, Backbone, Marionette, $, _) ->

  class Personal.Tax extends Marionette.ItemView
    template: 'advisor_home/billing/views/personal/tax_view_tmpl'

    ui:
      form:                              '#form-personal-phone'
      phoneInput:                        '#input-personal-phone'
      submitButton:                      '#submit-personal-phone'
      personalPhoneWraper:               '#collapse-edition-personal-phone'

      # validation messages
      phoneInvalid:                 '#phone-invalid'
      phoneExists:                  '#phone-exists'

    events:
      'submit @ui.form':                  'submitForm'
      'click @ui.submitButton':           'submitForm'

    submitForm: (e) ->
      e.preventDefault()
      @hideAllErrors()

    hideAllErrors: ->
      @ui.phoneInvalid.hide()
      @ui.phoneExists.hide()
