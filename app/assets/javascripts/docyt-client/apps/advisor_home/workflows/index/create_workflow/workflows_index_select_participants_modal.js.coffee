@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.SelectParticipantsModal extends Marionette.CompositeView
    template: 'advisor_home/workflows/index/create_workflow/workflows_index_select_participants_modal_tmpl'
    childViewContainer: '.modal-participants'

    SEARCH_DEBOUNCE_INTERVAL = 500

    getChildView: ->
      Index.ParticipantModal

    ui:
      back:   '.back-js'
      cancel: '.cancel-js'
      submit: '.submit-js'

      searchField: '.clients-search-input-js'

      noParticipantsError: '.participants-not-added-js'
      noClientsFoundError: '.clients-not-found-js'

    events:
      'click @ui.back':   'previousStep'
      'click @ui.cancel': 'closeModal'
      'click @ui.submit': 'setStandardCategoriesModal'

    onRender: ->
      @initAutocomplete()

    closeModal: ->
      @destroy()

    previousStep: ->
      modalView = new Index.SetWorkflowInfoModal
        model: @options.workflow

      @appendNewModal(modalView)

    setStandardCategoriesModal: ->
      if @collection.length > 0
        modalView = new Index.SetStandardCategoriesModal
          workflow: @options.workflow
          collection: @collection

        @appendNewModal(modalView)
      else
        @ui.noParticipantsError.show()

    appendNewModal: (modalView) ->
      Docyt.modalRegion.show(modalView)
      @destroy()

    appendListFoundClients: (clients) ->
      if clients.models.length > 0
        @ui.noClientsFoundError.hide()

        clientsJSON = clients.toJSON()
        @selectizeSelect[0].selectize.addOption(clientsJSON)
      else
        @ui.noClientsFoundError.show()

    selectizeHtml: (data, escape) ->
      "<div class=\"item\" data-folder-id=\"#{data.id}\">#{data.parsed_fullname}</div>"

    initAutocomplete: ->
      @selectizeSelect = @ui.searchField.selectize(
        placeholder: "Type Client Name/Email"
        loadThrottle: SEARCH_DEBOUNCE_INTERVAL
        valueField:  'id'
        labelField:  'parsed_fullname'
        searchField: ['parsed_fullname','email']
        render:
          item: (data, escape) =>
            @selectizeHtml(data, escape)
          option: (data, escape) =>
            @selectizeHtml(data, escape)
        load: (query, callback) =>
          if $.trim(query).length > 0
            Docyt.vent.trigger('show:spinner')

            searchData =
              searchPhrase: query.replace(/[^a-zA-Z0-9_]+/, '')

            @clients = new Docyt.Entities.Clients

            @clients.fetchWithSearch(searchData).success (response) =>
              Docyt.vent.trigger('hide:spinner')
              @appendListFoundClients(@clients)
              callback(@clients)
            .error =>
              Docyt.vent.trigger('hide:spinner')
              toastr.error('Search failed. Please try again.', 'Something went wrong.')
        onChange: (clientId) =>
          @addFoundClientToParticipants(clientId)
      )

    addFoundClientToParticipants: (clientId) ->
      client = _.find(@clients.models, id: parseInt(clientId) )

      if client
        participant = new Docyt.Entities.Participant(client.attributes)
        @collection.add(participant)

      @selectizeSelect[0].selectize.clearOptions()
