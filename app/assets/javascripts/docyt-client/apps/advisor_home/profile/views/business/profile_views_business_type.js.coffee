@Docyt.module 'AdvisorHomeApp.Profile.Views.Business', (Business, App, Backbone, Marionette, $, _) ->

  class Business.Type extends Marionette.ItemView
    template: 'advisor_home/profile/views/business/type_view_tmpl'

    templateHelpers: ->
      clientCategory: @model.get('category_name')
