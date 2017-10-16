@Docyt.module 'AdvisorHomeApp.Billing.Views.Personal', (Personal, App, Backbone, Marionette, $, _) ->

  class Personal.CreditCard extends Marionette.ItemView
    template: 'advisor_home/billing/views/personal/credit_card_view_tmpl'

    ui:
      form:         '#form-personal-name'
      submitButton: '#submit-personal-name'
      nameInput:    '#input-personal-name'
      companyInput:      '#input-company-name'
      addressInput:      '#input-bill-address'
      cityInput:         '#input-personal-city'
      stateInput:        '#input-personal-state'
      zipInput:          '#input-personal-zip'
      countyInput:       '#input-personal-country'

    events:
      'submit @ui.form':        'submitForm'
      'click @ui.submitButton': 'submitForm'

    initialize: ->
      @listenTo(@model, 'change:full_name', @render)

    onShow: ->
      @createCardElement()

    submitForm: (e) ->
      e.preventDefault()
      @getStripeToken().then (res) =>
        @addCreditCardInfo(res)

    getNamesFromString: (namesString) ->
      namesArray = namesString.split(' ')
      firstName = namesArray.shift()
      lastName = namesArray.join(' ')

      names =
        firstName:  firstName
        lastName:   lastName


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
        holder_name: @ui.nameInput.val(), 
        company: @ui.companyInput.val(), 
        bill_address: @ui.addressInput.val(), 
        city: @ui.cityInput.val(), 
        state: @ui.stateInput.val(), 
        zip: @ui.zipInput.val(), 
        country: @ui.countyInput.val(),
      )
      @model.save({}, url: "/api/web/v1/credit_cards").done =>
        $('#collapse-edition-card-info').collapse('hide')