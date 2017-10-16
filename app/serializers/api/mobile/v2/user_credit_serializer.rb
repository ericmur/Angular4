class Api::Mobile::V2::UserCreditSerializer < ActiveModel::Serializer
  attributes :fax_credit, :available, :current_usage, :dollar_credit

  def available
    serialization_options[:available]
  end

  def current_usage
    serialization_options[:current_usage]
  end
end