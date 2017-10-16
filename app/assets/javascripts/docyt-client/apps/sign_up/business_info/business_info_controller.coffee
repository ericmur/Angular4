@Docyt.module "SignUpApp.BusinessInfo", (BusinessInfo, App, Backbone, Marionette, $, _) ->

  class BusinessInfo.Controller extends Marionette.Object

    showBusinessInfo: ->
      return @navigateToSignIn() if Docyt.currentAdvisor.isEmpty()

      business = @getBusiness()
      @advisorTypes ||= new Backbone.Collection
      @entityTypes ||= new Backbone.Collection
      @advisorTypes.fetch(url: '/api/web/v1/advisor/advisor_types').done (response) =>
        @advisorTypes.set(response.standard_categories)
        @entityTypes.fetch(url: '/api/web/v1/businesses/get_entity_types').done (response) =>
          @entityTypes.set(response.entity_type)
          business.fetch(url: '/api/web/v1/businesses').done =>
            App.mainRegion.show(@getBusinessInfoView(business, @advisorTypes, @entityTypes))

    getBusinessInfoView: (business, advisorTypes, entityTypes) ->
      new BusinessInfo.AddBusinessInfo
        model: business
        advisorTypes: advisorTypes
        entityTypes: entityTypes

    navigateToSignIn: ->
      Backbone.history.navigate("/sign_in", trigger: true)

    getBusiness: ->
      new Docyt.Entities.Business
