class Api::Web::V1::WorkflowsQuery

  def initialize(current_advisor, params)
    @params = params
    @current_advisor = current_advisor
  end

  def get_all_workflows
    @current_advisor.workflows
  end

  def get_workflow
    @current_advisor.workflows.find_by(id: @params[:id])
  end
end
