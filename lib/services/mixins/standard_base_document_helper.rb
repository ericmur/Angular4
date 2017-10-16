module Mixins::StandardBaseDocumentHelper

  def set_owners(standard_base_document)
    @owners_params.each do |owner_hash|
      if owner_hash["owner_type"] == "GroupUser"
        group_user = GroupUser.find(owner_hash['owner_id'])
        owner = group_user.user.present? ? group_user.user : group_user
        standard_base_document.owners.build(owner: owner)
      elsif %[ Consumer User ].include?(owner_hash["owner_type"])
        consumer = User.find(owner_hash['owner_id'])
        standard_base_document.owners.build(owner: consumer)
      elsif owner_hash["owner_type"] == "Client"
        client = Client.find(owner_hash['owner_id'])
        owner = client.user.present? ? client.user : client
        standard_base_document.owners.build(owner: owner)
      elsif owner_hash["owner_type"] == "Business"
        business = Business.find(owner_hash['owner_id'])
        standard_base_document.owners.build(owner: business)
      end
    end if @owners_params.present?

    if standard_base_document.owners.blank?
      standard_base_document.owners.build(owner: @current_user)
    end
  end

  def set_permissions(standard_base_document)
    standard_base_document.owners.each do |o|
      Permission::VALUES.each do |value|
        standard_base_document.permissions.build(
          user: @current_user,
          folder_structure_owner: o.owner,
          value: value
        )
        if %[ Consumer User ].include?(o.owner.class.to_s) && o.owner != @current_user
          standard_base_document.permissions.build(
            user: o.owner,
            folder_structure_owner: o.owner,
            value: value
          )
        end
      end
    end
  end
end