@Docyt.module "Entities", (Entities, App, Backbone, Marionette, $, _) ->

  class Entities.Workflow extends Backbone.Model
    urlRoot: -> "/api/web/v1/workflows"
    paramRoot: 'workflow'

    initialize: ->
      @setWorkflowUrl()
      @setParticipantsCollection()
      @setStandardDocumentsCollection()

    parse: (response) ->
      if response.workflow then response.workflow else response

    setDeadline: ->
      timeNow = moment(new Date())
      workflowEndTime = moment(@get('end_date'))
      differentTime   = timeNow.diff(workflowEndTime, 'days')

      if differentTime < 0
        differentTime = Math.abs(differentTime)
        @set('remaining', differentTime)
        "#{moment(workflowEndTime).fromNow(true)} remaining"
      else if differentTime == 0
        @set('today', '')
        "Ended today"
      else
        @set('ago', differentTime)
        "Ended #{moment(workflowEndTime).fromNow()}"

    setWorkflowUrl: ->
      @set('url', "/workflows/#{@get('id')}")

    setParticipantsCollection: ->
      @set('participants', new Docyt.Entities.Participants(@get('participants')))

    setStandardDocumentsCollection: ->
      @set('standard_documents', new Docyt.Entities.StandardDocuments(@get('standard_documents')))
