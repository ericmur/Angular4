class Api::Web::V1::WorkflowsController < Api::Web::V1::ApiController
  before_action :get_workflows, only: :index
  before_action :get_workflow,  only: :show

  def index
    render status: 200, json: @workflows.order(:created_at), each_serializer: ::Api::Web::V1::WorkflowSerializer
  end

  def create
    workflow = Api::Web::V1::WorkflowBuilder.new(current_advisor, workflow_params).create_workflow

    if workflow.persisted?
      render status: 201, json: workflow, serializer: ::Api::Web::V1::WorkflowSerializer
    else
      render status: 422, json: workflow.errors
    end
  end

  def show
    if @workflow
      render status: 200, json: @workflow, serializer: ::Api::Web::V1::WorkflowSerializer
    else
      render status: 404, json: {}
    end
  end

  private

  def workflow_params
    params.require(:workflow).permit(
      :name, :kind, :purpose, :end_date, :same_documents_for_all,
      elements: [],
      participants: [:consumer_id, standard_documents: [:category_id]],
      standard_documents: [:category_id]
    )
  end

  def get_workflows
    @workflows = Api::Web::V1::WorkflowsQuery.new(current_advisor, params).get_all_workflows
  end

  def get_workflow
    @workflow = Api::Web::V1::WorkflowsQuery.new(current_advisor, params).get_workflow
  end

end
