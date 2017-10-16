class InvitationSerializer < ActiveModel::Serializer
  attributes :id, :accepted_at, :rejected_at, :accepted_by_user_id, :created_by_user_id, :email, :type
  attributes :email_invitation, :text_invitation, :created_at, :phone, :phone_normalized, :state, :invitee_type
end