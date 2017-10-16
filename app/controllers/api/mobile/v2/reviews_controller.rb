class Api::Mobile::V2::ReviewsController < Api::Mobile::V2::ApiController
  before_action :verify_eligible_to_review, only: [:show]
  before_action :load_review, only: [:show]

  def show
    render status: 200, json: { ask_for_review: @review.should_ask_review?(Rails.mobile_app_version) }
  end

  def create
    @review = current_user.build_review
    @review.last_version = Rails.mobile_app_version
    @review.refused = params[:refused].blank? ? false : %w[1 true].include?(params[:refused].to_s)
    @review.save
    render status: 200, nothing: true
  end

  private

  def verify_eligible_to_review
    unless current_user.eligible_to_review?
      render status: 200, json: { ask_for_review: false }
    end
  end

  def load_review
    @review = current_user.review
    unless @review.present?
      render status: 200, json: { ask_for_review: true }
    end
  end
end