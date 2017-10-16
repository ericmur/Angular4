@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Show", (Show, App, Backbone, Marionette, $, _) ->

  class Show.ConfirmPasswordModal extends Marionette.ItemView
    template: 'advisor_home/clients/show/documents/standard_folders/show/standard_folder_show_confirm_password_modal_tmpl'

    ENTER_KEY_CODE = 13

    ui:
      close:             '.close'
      cancel:            '.cancel'
      passwordInput:     '#password'
      confirmPassword:   '#confirm-password'
      incorrectPassword: '#password-incorrect'

    events:
      'click @ui.close': 'closeModal'
      'click @ui.cancel': 'closeModal'
      'click @ui.confirmPassword': 'submitForm'
      'keypress @ui.passwordInput' : 'submitWithEnter'

    initialize: ->
      Docyt.vent.on('show:not:confirmed:password:on:secure:folder', @showIncorrectPassword)
      Docyt.vent.on('destroy:modal:confirmation:password:on:secure:folder', => @destroy() )
      @client = @options.client

    onDestroy: ->
      Docyt.vent.off('show:not:confirmed:password:on:secure:folder')
      Docyt.vent.off('destroy:modal:confirmation:password:on:secure:folder')

    closeModal: ->
      @destroy()
      Backbone.history.navigate(@getBackUrl(), trigger: true )

    submitForm: ->
      if @passwordNotEmpty()
        @options.password = @ui.passwordInput.val()
        Docyt.vent.trigger(@getTrigger(), @options)
      else
        @ui.incorrectPassword.show()

    passwordNotEmpty: ->
      @ui.passwordInput.val().length

    submitWithEnter: (event) ->
      @submitForm() if event.keyCode == ENTER_KEY_CODE

    showIncorrectPassword: =>
      @ui.incorrectPassword.show()

    getBackUrl: ->
      if @isClient()
        "clients/#{@options.client.get('id')}/details/documents"
      else if @options.business
        "businesses/#{@options.business.get('id')}/standard_folders"
      else
        "contacts/#{@options.client.get('id')}/details/documents"

    getTrigger: ->
      if @isClient()
        "load:documents:after:confirm:password"
      else if @options.business
        "business:documents:load:documents:after:confirm:password"
      else if @options.ownDocuments
        "mydocuments:load:documents:after:confirm:password"
      else
        "contact:load:documents:after:confirm:password"

    isClient: ->
      @client && @client.get('type') == 'Client'
