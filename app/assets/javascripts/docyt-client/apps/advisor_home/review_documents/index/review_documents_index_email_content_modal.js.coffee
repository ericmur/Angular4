@Docyt.module "AdvisorHomeApp.ReviewDocuments.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.EmailContentModal extends Marionette.ItemView
    template: 'advisor_home/review_documents/index/review_documents_index_email_content_modal_tmpl'

    ui:
      cancel: '.cancel'

    events:
      'click @ui.cancel': 'closeModal'

    templateHelpers: ->
      emailBody: @model.getEmailBody()

    closeModal: ->
      @destroy()
