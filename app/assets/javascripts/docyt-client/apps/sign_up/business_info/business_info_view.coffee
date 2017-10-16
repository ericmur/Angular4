@Docyt.module "SignUpApp.BusinessInfo", (BusinessInfo, App, Backbone, Marionette, $, _) ->

  class BusinessInfo.AddBusinessInfo extends Marionette.ItemView
    template: 'sign_up/business_info/business_info_tmpl'

    ui:
      bizName:        '.biz-name-js'
      bizEntity:        '.entity-type-js'
      bizType:        '.biz-type-js'
      bizAddress1:        '.biz-address1-js'
      bizAddress2:        '.biz-address2-js'
      bizCity:        '.biz-city-js'
      bizState:        '.biz-state-js'
      bizZip:        '.biz-zip-js'
      bizCounty:        '.biz-country-js'
      bizContinue:       '.biz-continue-js'
      avatarUploading: '.avatar-upload-js'

      advisorTypeSelect:  '#type-menu'
      advisorTypeOption:  '.login-form__select-menu-item'
      advisorTypeOptions: '#select-options'
      advisorTypeSelectedOption: '#selected-option'

      entityTypeSelect:  '#entity-menu'
      entityTypeOption:  '.entity__select-menu-item'
      entityTypeOptions: '#entity-select-options'
      entityTypeSelectedOption: '#entity-selected-option'

      avatarError: '.avatar-invalid-error-js'

    events:
      'keyup @ui.bizName':   'toggleButtons'
      'change @ui.avatarUploading': 'avatarUploading'
      'click @ui.bizContinue': 'navigateCreditCardInfo'

      'click @ui.advisorTypeSelect': 'showSelectOptions'
      'click @ui.advisorTypeOption': 'setAdvisorType'

      'click @ui.entityTypeSelect': 'showEntityOptions'
      'click @ui.entityTypeOption': 'setEntityType'

    initialize: ->
      Docyt.vent.on('avatar:upload:success', @avatarUploaded)

    onDestroy: ->
      Docyt.vent.off('avatar:upload:success')

    onRender: ->
      @toggleButtons()

    onShow: ->
      @initSelectize()

    templateHelpers: ->
      advisorTypes: @options.advisorTypes.toJSON()
      entityTypes: @options.entityTypes.toJSON()
      avatarUrl: Docyt.currentAdvisor.getAmazonS3Url()

    navigateCreditCardInfo: ->
      @addBizInfo()
      @model.save({}, url: "/api/web/v1/businesses").done =>
        Backbone.history.navigate('/sign_up/credit', trigger: true)

    setAdvisorWorkspace: (type) ->
      @model.set(
        current_workspace_id: type.get('id')
        current_workspace_name: type.get('display_name')
      )
    
    toggleButtons: ->
      @ui.bizContinue.toggleClass('no-active', !@nameIsFilled())

    nameIsFilled: ->
      $.trim(@ui.bizName.val()).length > 0

    avatarUploading: (e) ->
      e.preventDefault()
      @ui.avatarError.hide()

      file = e.currentTarget.files[0]
      uploader = new Docyt.Services.UploadAvatarToS3Service(file, Docyt.currentAdvisor.get('id'), 'biz')

      return @ui.avatarError.show() unless uploader.isValid()

      uploader.upload()

    avatarUploaded: =>
      Docyt.currentAdvisor.fetch().success (response) =>
        Docyt.currentAdvisor.updateSelf(response.advisor)
        @render()

    addBizInfo: ->
      @model.set(
        name: @ui.bizName.val(), 
        address_state: @ui.bizState.val(), 
        address_street: @ui.bizAddress1.val(), 
        address_zip: @ui.bizZip.val(), 
        address_city: @ui.bizCity.val(),
        entity_type: @entityType
        standard_category_id: @advisorType
        update_standard_category: 1
      )

    showSelectOptions: (e) ->
      @ui.entityTypeOptions.hide()
      e.stopPropagation()
      if @ui.advisorTypeOptions.is(':visible')
        @ui.advisorTypeOptions.hide()
      else
        @ui.advisorTypeOptions.show()

    showEntityOptions: (e) ->
      e.stopPropagation()
      @ui.advisorTypeOptions.hide()
      if @ui.entityTypeOptions.is(':visible')
        @ui.entityTypeOptions.hide()
      else
        @ui.entityTypeOptions.show()

    setAdvisorType: (e) ->
      @ui.advisorTypeSelectedOption.text(e.currentTarget.textContent)
      @advisorType = e.currentTarget.dataset.option
      @ui.advisorTypeOptions.hide()

    setEntityType: (e) ->
      @ui.entityTypeSelectedOption.text(e.currentTarget.textContent)
      @entityType = e.currentTarget.dataset.option
      @ui.entityTypeOptions.hide()

    initSelectize: ->
      @ui.bizEntity.selectize
        valueField: 'text'
        labelField: 'text'
        create: false
        options: @getList()
        onChange: (value) =>
          @updateValue(value) if value
        
    getList: ->
      return @options.entityTypes.toJSON()

    updateValue: (value) ->
      @model.set(
        entity_type: value, 
      )

    initSelectHideHandler: ->
      $(document).click (e) => 
        @ui.advisorTypeOptions.hide()
        @ui.entityTypeOptions.hide()
