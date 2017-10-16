@Docyt.module "AdvisorHomeApp.Clients.Show.Documents.Index", (Index, App, Backbone, Marionette, $, _) ->

  class Index.СonfirmationModal extends Marionette.ItemView
    template: 'advisor_home/clients/show/documents/index/clients_documents_confirm_remove_modal_tmpl'

    ui:
      cancel:  '#cancel-remove'
      proceed: '#confirm-remove'

    events:
      'click @ui.cancel': 'destroy'

    triggers:
      'click @ui.proceed': 'confirm'
