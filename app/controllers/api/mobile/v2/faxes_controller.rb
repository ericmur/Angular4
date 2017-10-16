class Api::Mobile::V2::FaxesController < Api::Mobile::V2::ApiController
  before_action :set_fax, only: [:show, :retry, :check_status]
  before_action :load_user_password_hash, only: [:index, :create]
  before_action :load_document, only: [:create]
  before_action :verify_user_credit, only: [:create, :retry]

  def index
    render status: 200, json: current_user.faxes, each_serializer: Api::Mobile::V2::FaxSerializer
  end

  def show
    if @fax
      render status: 200, json: @fax, serializer: Api::Mobile::V2::FaxSerializer
    else
      render status: 404, json: {}
    end
  end

  def create
    fax = Fax.new(fax_params.merge(sender_id: current_user.id))

    if fax.save
      @user_credit.authorize_fax_credit!(fax, fax.pages_count)
      fax.document.share_with(:by_user_id => current_user.id, :with_user_id => nil)
      render status: 200, json: fax, serializer: Api::Mobile::V2::FaxSerializer
    else
      render status: 422, json: fax.errors
    end
  end

  def retry
    @fax.credit_transaction.destroy if @fax.credit_transaction
    @user_credit.authorize_fax_credit!(@fax, @fax.pages_count)
    @fax.document.share_with(:by_user_id => current_user.id, :with_user_id => nil)
    @fax.enqueue_send_fax
    render status: 200, nothing: true
  end

  def check_status
    render status: 200, json: { status: @fax.status }
  end

  private

  def fax_params
    params.require(:fax).permit(:document_id, :fax_number, :pages_count)
  end

  def set_fax
    @fax = current_user.faxes.find_by(id: params[:id])
  end

  def load_document
    @document = Document.find_by_id(params[:fax][:document_id])
    unless @document
      render status: 422, json: { errors: ["Unable to load document."] }
    end
  end

  def verify_user_credit
    fax_pages_count = @fax ? @fax.pages_count : params[:fax][:pages_count].to_i
    @user_credit = current_user.user_credit
    unless @user_credit.has_available_fax_credit?(fax_pages_count)
      render status: 422, json: { errors: ["You don't have enough credits to fax this document."] }
    end
  end

end
