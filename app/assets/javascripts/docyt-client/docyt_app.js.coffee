@Docyt = do (Backbone, Marionette) ->

  App = new Marionette.Application

  App.addRegions
    headerRegion: "#header-region"
    modalRegion:  "#modal-region"
    mainRegion:   "#main-region"
    # footerRegion: "#footer-region"

  App.setup = ->
    Backbone.$.ajaxSetup({
      headers: { 'X-User-Token': localStorage["auth_token"] }
    })

    Backbone.$.ajaxSetup({
      statusCode:
        401: ->
          params   = Backbone.history.location.search
          location = Backbone.history.location.pathname

          if location == '/sign_up'
            Backbone.history.navigate("/sign_up", { trigger: true })
          else
            location = '/sign_in' + params if params
            Backbone.history.navigate(location, { trigger: true })
    })

  App.on "start", (options) ->
    App.currentAdvisor = new App.Entities.CurrentAdvisor()
    App.setup()

    App.currentAdvisor.fetch(
      success: (response) =>
        App.currentAdvisor.updateSelf(response)
    ).always ->
      App.fayeClient = new App.Services.FayeClientBuilder().get_client()
      App.module('HeaderApp').start()

      new App.SignInApp.Login.Router({ controller: new App.SignInApp.Login.Controller })
      new App.SignUpApp.AddPhone.Router({ controller: new App.SignUpApp.AddPhone.Controller })
      new App.SignUpApp.Credentials.Router({ controller: new App.SignUpApp.Credentials.Controller })
      new App.SignUpApp.ConfirmPhone.Router({ controller: new App.SignUpApp.ConfirmPhone.Controller })
      new App.SignUpApp.ConfirmEmail.Router({ controller: new App.SignUpApp.ConfirmEmail.Controller })
      new App.SignUpApp.ConfirmPincode.Router({ controller: new App.SignUpApp.ConfirmPincode.Controller })
      new App.SignUpApp.ConfirmCredentials.Router({ controller: new App.SignUpApp.ConfirmCredentials.Controller })
      new App.SignUpApp.AccountTypeSelection.Router({ controller: new App.SignUpApp.AccountTypeSelection.Controller })
      new App.SignUpApp.BusinessInfo.Router({ controller: new App.SignUpApp.BusinessInfo.Controller })
      new App.SignUpApp.CreditCardInfo.Router({ controller: new App.SignUpApp.CreditCardInfo.Controller })

      new App.AdvisorHomeApp.Clients.Index.Router({ controller: new App.AdvisorHomeApp.Clients.Index.Controller })

      new App.AdvisorHomeApp.Clients.Show.Details.Router({ controller: new App.AdvisorHomeApp.Clients.Show.Details.Controller })

      new App.AdvisorHomeApp.Clients.Show.Documents.Index.Router({ controller: new App.AdvisorHomeApp.Clients.Show.Documents.Index.Controller })
      new App.AdvisorHomeApp.Clients.Show.Documents.Show.Router({ controller: new App.AdvisorHomeApp.Clients.Show.Documents.Show.Controller })

      new App.AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Show.Router({ controller: new App.AdvisorHomeApp.Clients.Show.Documents.Index.StandardFolders.Show.Controller })

      new App.AdvisorHomeApp.Clients.Show.Details.Contacts.Index.Router({ controller: new App.AdvisorHomeApp.Clients.Show.Details.Contacts.Index.Controller })

      new App.AdvisorHomeApp.Clients.Show.Messages.Router({ controller: new App.AdvisorHomeApp.Clients.Show.Messages.Controller })

      new App.AdvisorHomeApp.Contacts.Index.Router({ controller: new App.AdvisorHomeApp.Contacts.Index.Controller })
      new App.AdvisorHomeApp.Contacts.Show.Details.Router({ controller: new App.AdvisorHomeApp.Contacts.Show.Details.Controller })
      new App.AdvisorHomeApp.Contacts.Show.Messages.Router({ controller: new App.AdvisorHomeApp.Contacts.Show.Messages.Controller })
      new App.AdvisorHomeApp.Contacts.Show.Documents.Index.Router({ controller: new App.AdvisorHomeApp.Contacts.Show.Documents.Index.Controller })
      new App.AdvisorHomeApp.Contacts.Show.Documents.Index.StandardFolders.Show.Router({ controller: new App.AdvisorHomeApp.Contacts.Show.Documents.Index.StandardFolders.Show.Controller })
      new App.AdvisorHomeApp.Contacts.Show.Documents.Show.Router({ controller: new App.AdvisorHomeApp.Contacts.Show.Documents.Show.Controller })

      new App.AdvisorHomeApp.Workflows.Index.Router({ controller: new App.AdvisorHomeApp.Workflows.Index.Controller })
      new App.AdvisorHomeApp.Workflows.Show.Router({ controller: new App.AdvisorHomeApp.Workflows.Show.Controller })

      new App.AdvisorHomeApp.Workspace.Index.Router({ controller: new App.AdvisorHomeApp.Workspace.Index.Controller })

      new App.AdvisorHomeApp.Businesses.Show.StandardFolders.Index.Router({ controller: new App.AdvisorHomeApp.Businesses.Show.StandardFolders.Index.Controller })

      new App.AdvisorHomeApp.Messaging.Show.Router({ controller: new App.AdvisorHomeApp.Messaging.Show.Controller })

      new App.AdvisorHomeApp.Statistics.Show.Router({ controller: new App.AdvisorHomeApp.Statistics.Show.Controller })

      new App.AdvisorHomeApp.LatestDocuments.Index.Router({ controller: new App.AdvisorHomeApp.LatestDocuments.Index.Controller })

      new App.AdvisorHomeApp.Documents.Router({ controller: new App.AdvisorHomeApp.Documents.Controller })

      new App.AdvisorHomeApp.StandardFolders.Index.Router({ controller: new App.AdvisorHomeApp.StandardFolders.Index.Controller })

      new App.AdvisorHomeApp.ReviewDocuments.Index.Router({ controller: new App.AdvisorHomeApp.ReviewDocuments.Index.Controller })
      new App.AdvisorHomeApp.ReviewDocuments.Show.Router({ controller: new App.AdvisorHomeApp.ReviewDocuments.Show.Controller })

      new App.AdvisorHomeApp.Profile.Router({ controller: new App.AdvisorHomeApp.Profile.Controller })

      new App.AdvisorHomeApp.Billing.Router({ controller: new App.AdvisorHomeApp.Billing.Controller })

      if Backbone.history
        Backbone.history.start({ pushState: true })

  App
