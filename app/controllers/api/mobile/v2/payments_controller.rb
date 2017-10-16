class Api::Mobile::V2::PaymentsController < Api::Mobile::V2::ApiController

  # this callback is actually called within the mobile-app
  # some cases to be handled:
  # - Oauth expires before this action called
  # - User close or return to home when payment to apple is currently in progress
  def sk_payment_callback
    user_credit = current_user.user_credit
    purchase_item = PurchaseItem.where(product_identifier: params[:product_identifier]).first
    transaction_identifier = params[:transaction_identifier]
    transaction_date = params[:transaction_date]
    user_credit.purchase_fax_credit!(purchase_item, purchase_item.fax_credit_value,
      transaction_identifier, transaction_date)
    render status: 200, nothing: true
  end
end