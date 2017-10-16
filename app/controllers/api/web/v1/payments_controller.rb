require 'slack_helper'
class Api::Web::V1::PaymentsController < ActionController::Base

  protect_from_forgery except: :webhook
  def webhook
    event = Stripe::Event.retrieve(params["id"])

    case event.type
      when "charge.succeeded"
      charge_info = event.data.object
      if credit_card = CreditCard.find_by(customer_token: charge_info.customer)
        charged_uid = credit_card.user_id
        PaymentTransaction.create(amount: charge_info.amount/100.to_f, date: Time.at(charge_info.created), user_id: charged_uid)
      else
        SlackHelper.ping({ channel: "#errors", username: "StripePayment", message: "Charge corresponding to stripe token not found in DB" })
      end
    end
    render status: :ok, json: "success"
  end
end
