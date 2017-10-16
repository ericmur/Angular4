@Docyt.module "Common", (Common, App, Backbone, Marionette, $, _) ->

  class Common.SecuredRouter extends Marionette.AppRouter

    # we need to return false in order to stop other routes from triggering
    # so it works like a before_action in Rails
    before: ->
      if Docyt.currentAdvisor.isEmpty() || !Docyt.currentAdvisor.get('web_app_is_set_up')
        Backbone.history.navigate("/sign_in", trigger: true)
        false
      else
        @redirectToPage()

    redirectToPage: ->
      if !Docyt.currentAdvisor.get('phone_normalized')
        @addPhonePage()
      else if !Docyt.currentAdvisor.get('phone_confirmed_at')
        @confirmPhonePage()
      else if !Docyt.currentAdvisor.get('email_confirmed_at')
        @confirmEmailPage()
      else if !Docyt.currentAdvisor.get('consumer_account_type_id')
        @selectAccountTypePage()

    addPhonePage: ->
      Backbone.history.navigate("/sign_up/add_phone", trigger: true)
      false

    confirmPhonePage: ->
      Backbone.history.navigate("/sign_up/confirm_phone", trigger: true)
      false

    confirmEmailPage: ->
      Backbone.history.navigate("/sign_up/confirm_email", trigger: true)
      false

    selectAccountTypePage: ->
      Backbone.history.navigate("/sign_up/account_type_selection", trigger: true)
      false
