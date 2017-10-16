class WorkflowService
  def initialize(params)
    @params   = params
    @user     = set_user
    @workflow = set_workflow

    @standard_document = set_standard_document
  end

  def create_workflow
    return unless @user

    workflow = Workflow.create(admin: @user, name: @params[:name], end_date: @params[:end_date])
  end

  def add_participant
    return unless @workflow && @user

    participant = @workflow.participants.create(user: @user)
  end

  def add_standard_document
    return unless @workflow && @standard_document

    @workflow.workflow_standard_documents.create(standard_document: @standard_document)
  end

  def require_participant_to_upload
    participant = @workflow.participants.find_by(user_id: @params[:user_id]) if @workflow

    return unless participant && @standard_document

    participant.workflow_standard_documents.create(standard_document: @standard_document)
  end

  private

  def set_workflow
    Workflow.find_by(id: @params[:workflow_id])
  end

  def set_user
    User.find_by(id: @params[:user_id])
  end

  def set_standard_document
    StandardDocument.find_by(id: @params[:standard_document_id])
  end
end
