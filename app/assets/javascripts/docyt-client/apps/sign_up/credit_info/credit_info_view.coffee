@Docyt.module "SignUpApp.CreditCardInfo", (CreditCardInfo, App, Backbone, Marionette, $, _) ->

  class CreditCardInfo.AddCreditCardInfo extends Marionette.ItemView
    template: 'sign_up/credit_info/credit_info_tmpl'

    ui:
      creditName:         '.credit-name-js'
      creditCompany:      '.credit-company-js'
      creditAddress1:     '.credit-address1-js'
      creditAddress2:     '.credit-address2-js'
      creditCity:         '.credit-city-js'
      creditState:        '.credit-state-js'
      creditZip:          '.credit-zip-js'
      creditCounty:       '.credit-country-js'
      creditSubmit:       '.credit-submit-js'

      linkAnnual:       '.link-annual'
      linkMonthly:       '.link-monthly'

    events:
      'keyup @ui.creditName':   'toggleButtons'
      'click @ui.creditSubmit': 'navigateWorkspace'
      'click @ui.linkAnnual': 'showAnnual'
      'click @ui.linkMonthly': 'showMonthly'

    initialize: ->

    onDestroy: ->

    onRender: ->
      @toggleButtons()

    onShow: ->
      @showMonthly()
      @createCardElement()

    templateHelpers: ->
      accType: @options.accType

    navigateWorkspace: ->
      @getStripeToken().then (res) =>
        @addCreditCardInfo(res)

    toggleButtons: ->
      @ui.creditSubmit.toggleClass('no-active', !@nameIsFilled())

    nameIsFilled: ->
      $.trim(@ui.creditName.val()).length > 0

    createCardElement: ->
      @stripe = Stripe(configData.stripePublishableKey)
      elements = @stripe.elements()
      style = 
        base:
          color: '#32325d'
          lineHeight: '24px'
          fontFamily: '"Helvetica Neue", Helvetica, sans-serif'
          fontSmoothing: 'antialiased'
          fontSize: '16px'
          '::placeholder': color: '#aab7c4'
        invalid:
          color: '#fa755a'
          iconColor: '#fa755a'
      @card = elements.create('card', style: style)
      @card.mount '#card-element'

      @card.addEventListener 'change', (event) ->
        displayError = document.getElementById('card-errors')
        if event.error
          displayError.textContent = event.error.message
        else
          displayError.textContent = ''
        return

    getStripeToken: ->
      @stripe.createToken(@card).then (result) ->
        if result.error
          errorElement = document.getElementById('card-errors')
          errorElement.textContent = result.error.message
        else
          cardElement = document.getElementById('card-element')
          hiddenInput = document.createElement('input')
          hiddenInput.setAttribute 'type', 'hidden'
          hiddenInput.setAttribute 'name', 'stripeToken'
          hiddenInput.setAttribute 'id', 'stripeToken'
          hiddenInput.setAttribute 'value', result.token.id
          cardElement.appendChild hiddenInput
          stripeToken = result.token.id

    addCreditCardInfo: (stripeToken) ->
      @model.set(
        stripe_token: stripeToken, 
        holder_name: @ui.creditName.val(), 
        company: @ui.creditCompany.val(), 
        bill_address: @ui.creditAddress1.val(), 
        city: @ui.creditCity.val(), 
        state: @ui.creditState.val(), 
        zip: @ui.creditZip.val(), 
        country: @ui.creditCounty.val(),
      )
      @model.save({}, url: "/api/web/v1/credit_cards").done =>
        Backbone.history.navigate('/select_workspace', trigger: true)

    showAnnual: ->
      @model.set(
        subscription_type: "year", 
      )
      $('.sub-monthly').addClass 'hidden'
      $('.sub-annual').removeClass 'hidden'

    showMonthly: ->
      @model.set(
        subscription_type: "month", 
      )
      $('.sub-annual').addClass 'hidden'
      $('.sub-monthly').removeClass 'hidden'
