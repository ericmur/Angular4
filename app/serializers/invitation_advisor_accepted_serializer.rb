class InvitationAdvisorAcceptedSerializer < ActiveModel::Serializer
  attributes :id, :accepted_at, :state, :advisor, :type

  def advisor
    AdvisorSerializer.new(object.created_by_user, { :scope => scope, :root => false })
  end
end