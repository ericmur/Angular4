@Docyt.module "SignUpApp.ConfirmPincode", (ConfirmPincode, App, Backbone, Marionette, $, _) ->

  class ConfirmPincode.ConfirmPincodeNumber extends Marionette.ItemView
    template:  'sign_up/confirm_pincode/confirm_pincode_tmpl'

    PIN_SIZE = 6

    ui:
      submit:       '.submit-js'
      pinCodeInput: '.pincode-input-js'

      invalidPinCode:   '.invalid-pin-code-js'
      incorrectPinCode: '.incorrect-pin-code-js'

    events:
      'click @ui.submit': 'parsePinCode'

    onRender: ->
      @initPinCodeInput()

    initPinCodeInput: ->
      @ui.pinCodeInput.pincodeInput(hidedigits:true, inputs:PIN_SIZE)
      @ui.pinCodeInput.pincodeInput().data('plugin_pincodeInput').focus()

    parsePinCode: ->
      @hideAllErrors()

      pinCode = @ui.pinCodeInput.val()

      if $.trim(pinCode).length != PIN_SIZE
        @ui.invalidPinCode.show()
      else
        @pinCodeIsNumber(pinCode)

    pinCodeIsNumber: (pinCode) ->
      result = parseInt(pinCode)

      if _.isNaN(result) || result.toString().length != PIN_SIZE
        @ui.invalidPinCode.show()
        false
      else
        Docyt.currentAdvisor.set('pincode', pinCode)
        @sendPinCode()
        true

    sendPinCode: ->
      Docyt.currentAdvisor.save({}, url: '/api/web/v1/advisor/confirm_pincode').success (response) =>
        Docyt.currentAdvisor.set('valid_pin', response.pincode_status.valid_pin)
        Backbone.history.navigate("/sign_up/confirm_credentials", { trigger: true })
      .error =>
        @ui.incorrectPinCode.show()

    hideAllErrors: ->
      @ui.invalidPinCode.hide()
      @ui.incorrectPinCode.hide()
