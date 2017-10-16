@Docyt.module 'AdvisorHomeApp.Profile.Views.Personal', (Personal, App, Backbone, Marionette, $, _) ->

  class Personal.Name extends Marionette.ItemView
    template: 'advisor_home/profile/views/personal/name_view_tmpl'

    ui:
      form:         '#form-personal-name'
      nameInput:    '#input-personal-name'
      submitButton: '#submit-personal-name'

    events:
      'submit @ui.form':        'submitForm'
      'click @ui.submitButton': 'submitForm'

    initialize: ->
      @listenTo(@model, 'change:full_name', @render)

    submitForm: (e) ->
      e.preventDefault()

      names = @getNamesFromString(@ui.nameInput.val())
      @model.set(first_name: names.firstName, last_name: names.lastName)

      @model.updateCurrentAdvisor()

    getNamesFromString: (namesString) ->
      namesArray = namesString.split(' ')
      firstName = namesArray.shift()
      lastName = namesArray.join(' ')

      names =
        firstName:  firstName
        lastName:   lastName
