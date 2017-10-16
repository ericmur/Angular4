@Docyt.module "SignUpApp.AccountTypeSelection", (AccountTypeSelection, App, Backbone, Marionette, $, _) ->

  class AccountTypeSelection.SelectAccountType extends Marionette.ItemView
    template: 'sign_up/account_type_selection/account_type_selection_tmpl'

    ui:
      userName:        '.user-name-js'
      tryBizFree:      '.biz-try-free-js'
      getStarted:      '.get-started-js'
      freeContinue:    '.free-continue-js'
      tryFamilyFree:   '.family-try-free-js'
      avatarUploading: '.avatar-upload-js'

      avatarError: '.avatar-invalid-error-js'

    events:
      'keyup @ui.userName':      'toggleButtons'
      'click @ui.tryBizFree':    'navigateBizInfo'
      'click @ui.freeContinue':  'navigateIndividualWorkspace'
      'click @ui.tryFamilyFree': 'navigateCreditCardInfo'

      'change @ui.avatarUploading': 'avatarUploading'

    initialize: ->
      Docyt.vent.on('avatar:upload:success', @avatarUploaded)

    onDestroy: ->
      Docyt.vent.off('avatar:upload:success')

    onRender: ->
      @toggleButtons()

    templateHelpers: ->
      avatarUrl: @model.getAdvisorAvatarUrl()

    navigateBizInfo: ->
      @setUserName(@getNamesFromString(@ui.userName.val()))
      @options.accountTypes.fetch(url: '/api/web/v1/consumer_account_types').done =>
        @setAdvisorWorkspace(@options.accountTypes.getType('Business'))
        @model.save({}, url: "/api/web/v1/advisor/#{@model.get('id')}").done =>
          Backbone.history.navigate('/sign_up/business', trigger: true)

    navigateCreditCardInfo: ->
      @setUserName(@getNamesFromString(@ui.userName.val()))
      @options.accountTypes.fetch(url: '/api/web/v1/consumer_account_types').done =>
        @setAdvisorWorkspace(@options.accountTypes.getType('Family'))
        @model.save({}, url: "/api/web/v1/advisor/#{@model.get('id')}").done =>
          Backbone.history.navigate('/sign_up/credit', trigger: true)

    navigateIndividualWorkspace: ->
      @setUserName(@getNamesFromString(@ui.userName.val()))
      @options.accountTypes.fetch(url: '/api/web/v1/consumer_account_types').done =>
        @setAdvisorWorkspace(@options.accountTypes.getType('Free Forever'))
        @model.save({}, url: "/api/web/v1/advisor/#{@model.get('id')}").done =>
          Backbone.history.navigate('/my_documents', trigger: true)
          Docyt.vent.trigger('current:advisor:updated')

    setAdvisorWorkspace: (type) ->
      if type.get('display_name') == 'Business'
        @model.set(
          consumer_account_type_id: type.get('id')
          current_workspace_name: type.get('display_name')
        )
      else
        @model.set(
          consumer_account_type_id: type.get('id')
          current_workspace_id: type.get('id')
          current_workspace_name: type.get('display_name')
        )

    showSelectAdvisorTypeModal: ->
      return unless @nameIsFilled()

      @setUserName(@getNamesFromString(@ui.userName.val()))

      @fetchAdvisorTypes()

    toggleButtons: ->
      @ui.tryFamilyFree.toggleClass('no-active', !@nameIsFilled())
      @ui.tryBizFree.toggleClass('no-active', !@nameIsFilled())
      @ui.getStarted.toggleClass('no-active', !@nameIsFilled())

    nameIsFilled: ->
      $.trim(@ui.userName.val()).length > 0

    avatarUploading: (e) ->
      e.preventDefault()
      @ui.avatarError.hide()

      file = e.currentTarget.files[0]
      uploader = new Docyt.Services.UploadAvatarToS3Service(file, @model.get('id'), 'user')

      return @ui.avatarError.show() unless uploader.isValid()

      uploader.upload()

    avatarUploaded: =>
      @model.fetch().success (response) =>
        @model.updateSelf(response.advisor)
        @render()

    getNamesFromString: (namesString) ->
      namesArray = namesString.split(' ')
      firstName = namesArray.shift()
      lastName = namesArray.shift()

      fullName =
        firstName:  firstName
        lastName:   lastName

    setUserName: (fullName) ->
      @model.set(first_name: fullName.firstName, last_name: fullName.lastName)

    fetchAdvisorTypes: ->
      @advisorTypes ||= new Backbone.Collection

      if @advisorTypes.length > 0
        @getSelectAdvisorTypeModal(@advisorTypes, @options.accountTypes)
      else
        @advisorTypes.fetch(url: '/api/web/v1/advisor/advisor_types').done (response) =>
          @advisorTypes.set(response.standard_categories)
          @getSelectAdvisorTypeModal(@advisorTypes, @options.accountTypes)

    getSelectAdvisorTypeModal: (advisorTypes, accountTypes) ->
      modalView = new AccountTypeSelection.SelectAdvisorCategory
        model: @model
        advisorTypes: advisorTypes
        accountTypes: accountTypes

      Docyt.modalRegion.show(modalView)
