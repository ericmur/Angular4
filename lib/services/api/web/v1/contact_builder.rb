class Api::Web::V1::ContactBuilder

  def initialize(advisor, contact_params)
    @params  = contact_params
    @advisor = advisor

    @contact_params    = contact_params.except('invitation', :standard_group_id)
    @standard_group_id = contact_params[:standard_group_id]
    @invitation_params = contact_params['invitation']

    @errors_hash = {}
  end

  def create_contact_and_invitation
    build_contact
    build_invitation if @invitation_params

    check_and_save_invitation_and_contact
  end

  def errors
    @errors_hash
  end

  def contact
    @contact
  end

  private

  def build_invitation
    invitation_builder = Api::Web::V1::InvitationBuilder.new(@advisor, @params)
    @invitation = invitation_builder.build_invitation

    @errors_hash['invitation_errors'] = invitation_builder.errors unless @invitation.valid?
  end

  def build_contact
    @contact = GroupUser.new(@contact_params)
    @contact.group = set_group

    @errors_hash['contact_errors'] = @contact.errors.full_messages unless @contact.valid?
  end

  def check_and_save_invitation_and_contact
    if @contact && @invitation
      if @contact.errors.blank? && @invitation.errors.blank?
        @contact.save
        @invitation.group_user_id = @contact.id
        @invitation.save
      end

    else
      @contact.save if @contact.errors.blank?
    end
  end

  def set_group
    standard_group = StandardGroup.find_by(id: @standard_group_id)

    return unless standard_group

    group = Group.joins(:standard_group)
              .where(standard_groups: { id: standard_group.id },groups: { owner_id: @advisor.id }).first

    group = Group.create(owner: @advisor, standard_group: standard_group) unless group

    group
  end

end
