@Docyt.module "AdvisorHomeApp.Profile", (Profile, App, Backbone, Marionette, $, _) ->

  class Profile.Controller extends Marionette.Object

    showAdvisorProfilePage: ->
      return @navigateToSignIn() if Docyt.currentAdvisor.isEmpty()

      advisorProfileLayout = @getAdvisorProfileLayoutView()
      App.mainRegion.show(advisorProfileLayout)

      currentAdvisor = @getCurrentAdvisor()

      profilePersonalLayout = @getAdvisorPersonalLayout()
      advisorProfileLayout.profilePersonalRegion.show(profilePersonalLayout)
      @buildProfilePersonalLayout(profilePersonalLayout, currentAdvisor)

      profileBusinessLayout = @getAdvisorBusinessLayout()
      advisorProfileLayout.profileBusinessRegion.show(profileBusinessLayout)
      @buildProfileBusinessLayout(profileBusinessLayout, currentAdvisor)

      profileSecurityLayout = @getAdvisorSecurityLayout()
      advisorProfileLayout.profileSecurityRegion.show(profileSecurityLayout)
      @buildProfileSecurityLayout(profileSecurityLayout, currentAdvisor)

    getCurrentAdvisor: ->
      Docyt.currentAdvisor

    getAdvisorProfileLayoutView: ->
      new Profile.Layout()

    getAdvisorPersonalLayout: ->
      new Profile.Layouts.Personal()

    getAdvisorBusinessLayout: ->
      new Profile.Layouts.Business()

    getAdvisorSecurityLayout: ->
      new Profile.Layouts.Security()

    buildProfilePersonalLayout: (profilePersonalLayout, currentAdvisor) ->
      personalAvatarView = @getPersonalAvatarView(currentAdvisor)
      profilePersonalLayout.profileAvatarRegion.show(personalAvatarView)

      personalNameView = @getPersonalNameView(currentAdvisor)
      profilePersonalLayout.profileNameRegion.show(personalNameView)

      personalEmailView = @getPersonalEmailView(currentAdvisor)
      profilePersonalLayout.profileEmailRegion.show(personalEmailView)

      personalPasswordView = @getPersonalPasswordView(currentAdvisor)
      profilePersonalLayout.profilePasswordRegion.show(personalPasswordView)

      personalPhoneView = @getPersonalPhoneView(currentAdvisor)
      profilePersonalLayout.profilePhoneRegion.show(personalPhoneView)

      personalForwardingEmailView = @getPersonalForwardingEmailView(currentAdvisor)
      profilePersonalLayout.profileForwardingEmailRegion.show(personalForwardingEmailView)

    getPersonalAvatarView: (currentAdvisor) ->
      new Profile.Views.Personal.Avatar({ model: currentAdvisor })

    getPersonalNameView: (currentAdvisor) ->
      new Profile.Views.Personal.Name({ model: currentAdvisor })

    getPersonalEmailView: (currentAdvisor) ->
      new Profile.Views.Personal.Email({ model: currentAdvisor })

    getPersonalPasswordView: (currentAdvisor) ->
      new Profile.Views.Personal.Password({ model: currentAdvisor })

    getPersonalPhoneView: (currentAdvisor) ->
      new Profile.Views.Personal.Phone({ model: currentAdvisor })

    getPersonalForwardingEmailView: (currentAdvisor) ->
      new Profile.Views.Personal.ForwardingEmail({ model: currentAdvisor })

    buildProfileBusinessLayout: (profileBusinessLayout, currentAdvisor) ->
      businessTypeView = @getBusinessTypeView(currentAdvisor)
      profileBusinessLayout.profileTypeRegion.show(businessTypeView)

      businessAddressView = @getBusinessAddressView(currentAdvisor)
      profileBusinessLayout.profileAddressRegion.show(businessAddressView)

    getBusinessTypeView: (currentAdvisor) ->
      new Profile.Views.Business.Type({ model: currentAdvisor })

    getBusinessAddressView: (currentAdvisor) ->
      new Profile.Views.Business.Address({ model: currentAdvisor })

    buildProfileSecurityLayout: (profileSecurityLayout, currentAdvisor) ->
      securityAuthenticationView = @getSecurityAuthenticationView(currentAdvisor)
      profileSecurityLayout.profileAuthenticationRegion.show(securityAuthenticationView)

      securityEncryptionView = @getSecurityEncryptionView(currentAdvisor)
      profileSecurityLayout.profileEncryptionRegion.show(securityEncryptionView)

      securityLocationsView = @getSecurityLocationsView(currentAdvisor)
      profileSecurityLayout.profileLocationsRegion.show(securityLocationsView)

    getSecurityAuthenticationView: (currentAdvisor) ->
      new Profile.Views.Security.Authentication({ model: currentAdvisor })

    getSecurityEncryptionView: (currentAdvisor) ->
      new Profile.Views.Security.Encryption({ model: currentAdvisor })

    getSecurityLocationsView: (currentAdvisor) ->
      new Profile.Views.Security.Locations({ model: currentAdvisor })

    navigateToSignIn: ->
      Backbone.history.navigate('/sign_in', trigger: true)
