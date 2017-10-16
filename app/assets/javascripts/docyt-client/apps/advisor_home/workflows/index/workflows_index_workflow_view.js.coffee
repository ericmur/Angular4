@Docyt.module "AdvisorHomeApp.Workflows.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.WorkflowView extends Marionette.ItemView
    template:  'advisor_home/workflows/index/workflow_view_tmpl'

    WEEK = 7

    ui:
      progressBar:   '.file-status-line'
      workflowElem:  '.workflows__workflow'
      messagesLink:  '.messages-link-js'
      documentsElem: '.documents-progress-js'
      remainingTime: '.remaining-time-js'

      otherPaticipants: '.other-participants-js'

    events:
      'click @ui.otherPaticipants': 'showParticipantsListModal'

    templateHelpers: ->
      endTime: @model.setDeadline()

      workflowUrl:                @model.get('url')
      workflowStatus:             @model.get('status')
      participantsCount:          @model.get('participants_count')
      countUploadedDocuments:     @model.get('uploaded_documents_count')
      namesFirstTwoParticipants:  @haveParticipants()
      countRemainingParticipants: @getCountRemainingParticipants()

      categoriesCountWithDocuments: @model.get('count_of_categories_with_documents')

    onRender: ->
      @setupColor()
      @hideMessagesIfWorkflowEnded()
      @calculateProgressDocumentsUploaded()

    setupColor: ->
      if @model.get('remaining') <= WEEK
        @ui.remainingTime.addClass('in-pink-400')
      else if @isPastWorkflow()
        @ui.workflowElem.addClass('disable-panel')

    hideMessagesIfWorkflowEnded: ->
      @ui.messagesLink.hide() if @isPastWorkflow()

    isPastWorkflow: ->
      @model.has('ago') || @model.has('today')

    haveParticipants: ->
      if @model.get('participants').length > 0
        @setNamesForParticipants()
      else
        'No participants'

    setNamesForParticipants: ->
      firstTwoParticipants = _.first(@model.get('participants').models, 2)

      result = ''
      _.each(firstTwoParticipants, (participant, index) ->
        if _.last(firstTwoParticipants).id == participant.id
          result += "#{participant.get('full_name')}"
        else
          result += "#{participant.get('full_name')}, "
      )
      result

    getCountRemainingParticipants: ->
      @model.get('participants').length - 2

    showParticipantsListModal: ->
      modalView = new Index.ParticipantsModal
        workflow:   @model
        collection: @model.get('participants')

      Docyt.modalRegion.show(modalView)

    calculateProgressDocumentsUploaded: ->
      if @model.get('status') == 'started'
        width = 100 / @model.get('expected_documents_count') * @model.get('uploaded_documents_count')
        @ui.progressBar.width("#{width}%")
