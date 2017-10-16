@Docyt.module 'AdvisorHomeApp.Billing.Views.Subscription', (Subscription, App, Backbone, Marionette, $, _) ->

  class Subscription.Plan extends Marionette.ItemView
    template: 'advisor_home/billing/views/subscription/plan_view_tmpl'

    ui:
      editBtn: '.settings-edit-btn'
      address: '.client__settings-edit-field'
      editForm: '.client__settings-edition-wrapper'

      linkAnnual:       '.billing-annual'
      linkMonthly:       '.billing-monthly'
      radioFamilyMonth:       '.radio-family-monthly'
      radioBizMonth:       '.radio-biz-monthly'
      radioFamilyYear:       '.radio-family-annual'
      radioBizYear:       '.radio-biz-annual'

      submitButton: '#submit-sub-plan'

    events:
      'click @ui.editBtn': 'showEditForm'
      'click @ui.linkAnnual': 'showAnnual'
      'click @ui.linkMonthly': 'showMonthly'
      'click @ui.radioFamilyMonth': 'setFamilyMonth'
      'click @ui.radioBizMonth': 'setBizMonth'
      'click @ui.radioFamilyYear': 'setFamilyYear'
      'click @ui.radioBizYear': 'setBizYear'

      'submit @ui.form':        'submitForm'
      'click @ui.submitButton': 'submitForm'

    templateHelpers: ->
      accType: @options.accType

    showEditForm: ->
      height = @ui.address.outerHeight()
      @ui.editForm.css('top', -(height))

    showAnnual: ->
      @model.set(
        subscription_type: "year", 
      )
      $('.billing-monthly-js').addClass 'hidden'
      $('.billing-annual-js').removeClass 'hidden'

    showMonthly: ->
      @model.set(
        subscription_type: "month", 
      )
      $('.billing-annual-js').addClass 'hidden'
      $('.billing-monthly-js').removeClass 'hidden'

    setFamilyMonth: ->
      $('input:radio').removeAttr 'checked'
      $('.radio-family-monthly > input:radio').prop 'checked', true
      @model.set(
        subscription_type: "month", 
        account_type: "Family" 
      )

    setBizMonth: ->
      $('input:radio').removeAttr 'checked'
      $('.radio-biz-monthly > input:radio').prop 'checked', true
      @model.set(
        subscription_type: "month", 
        account_type: "Business" 
      )

    setFamilyYear: ->
      $('input:radio').removeAttr 'checked'
      $('.radio-family-annual > input:radio').prop 'checked', true
      @model.set(
        subscription_type: "year", 
        account_type: "Family" 
      )

    setBizYear: ->
      $('input:radio').removeAttr 'checked'
      $('.radio-biz-annual > input:radio').prop 'checked', true
      @model.set(
        subscription_type: "year", 
        account_type: "Business" 
      )

    submitForm: (e) ->
      e.preventDefault()

      @model.save({}, url: "/api/web/v1/subscriptions").done =>
        $('#collapse-edition-subscription-plan').collapse('hide')