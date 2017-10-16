@Docyt.module 'AdvisorHomeApp.Profile.Views.Business', (Business, App, Backbone, Marionette, $, _) ->

  class Business.Address extends Marionette.ItemView
    template: 'advisor_home/profile/views/business/address_view_tmpl'

    ui:
      editBtn: '.settings-edit-btn'
      address: '.client__settings-edit-field'
      editForm: '.client__settings-edition-wrapper'

    events:
      'click @ui.editBtn': 'showEditForm'

    showEditForm: ->
      height = @ui.address.outerHeight()
      @ui.editForm.css('top', -(height))
