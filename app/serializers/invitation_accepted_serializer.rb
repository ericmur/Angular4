class InvitationAcceptedSerializer < ActiveModel::Serializer
  attributes :id, :accepted_at, :state, :invitee_group_user, :invitee_type, :type

  def invitee_group_user
    group_user = object.accepted_by_user.group_users_as_group_owner.where(user_id: object.created_by_user_id).first
    GroupUserSerializer.new(group_user, { :scope => scope, :root => false })
  end
end