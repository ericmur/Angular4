@Docyt.module "SignUpApp.ConfirmEmail", (ConfirmEmail, App, Backbone, Marionette, $, _) ->

  class ConfirmEmail.ConfirmEmailView extends Marionette.ItemView
    template:  'sign_up/confirm_email/confirm_email_tmpl'
    className: 'confirm-email'

    ui:
      resendEmail: '.resend-email-js'

    events:
      'click @ui.resendEmail': 'resendEmail'

    templateHelpers: ->
      verifyEmail: @getToVerifyEmail()

    resendEmail: ->
      Docyt.currentAdvisor.fetch(url: "/api/web/v1/advisor/resend_email_confirmation").done =>
        toastr.success('Email has been sent successfully. Check your mail.', 'Email was sent.')

    getToVerifyEmail: ->
      if Docyt.currentAdvisor.get('unverified_email')
        Docyt.currentAdvisor.get('unverified_email')
      else
        Docyt.currentAdvisor.get('email')
