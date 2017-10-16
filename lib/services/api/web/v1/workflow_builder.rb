class Api::Web::V1::WorkflowBuilder

  def initialize(advisor, params)
    @params  = params
    @advisor = advisor

    @workflow_params   = params.except(:participants, :standard_documents, :elements, :same_documents_for_all)
    @workflow_elements = params[:elements]

    @participants_params       = params[:participants]
    @standard_documents_params = params[:standard_documents]
  end

  def create_workflow
    workflow = Workflow.new(@workflow_params.merge(admin_id: @advisor.id))

    if workflow.valid?
      build_participants_and_standard_documents(workflow)
      workflow.save
    end

    workflow
  end

  private

  def build_participants_and_standard_documents(workflow)
    @participants_params.each do |participant_param|
      participant = workflow.participants.new(user_id: participant_param[:consumer_id])

      if @params[:same_documents_for_all] && @standard_documents_params
        build_workflow_standard_documents(workflow, @standard_documents_params)
      elsif participant_param[:standard_documents]
        build_workflow_standard_documents(participant, participant_param[:standard_documents])
      end

    end
  end

  def build_workflow_standard_documents(item, standard_documents_params)
    standard_documents_params.each do |standard_document_param|
      item.workflow_standard_documents.new(ownerable: item, standard_document_id: standard_document_param[:category_id])
    end
  end

end
