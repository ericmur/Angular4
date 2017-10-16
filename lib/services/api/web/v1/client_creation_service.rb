class Api::Web::V1::ClientCreationService

  def initialize(current_advisor, client_params)
    @params  = client_params
    @advisor = current_advisor

    @client_params     = client_params.except('invitation')
    @invitation_params = client_params['invitation']

    @errors_hash = {}
  end

  def create_client_and_invitation
    build_client
    build_invitation unless @invitation_params.blank?

    check_and_save_invitation_and_client
  end

  def client
    @client
  end

  def invitation
    @invitation
  end

  def errors
    @errors_hash
  end

  private

  def set_business
    return if @client.business.present?
    businesses = Business.for_user(@advisor)
    # we will only set business automatically if there's only one business for current_user
    if businesses.count == 1
      @client.business = businesses.first
    end
  end

  def build_invitation
    invitation_builder = Api::Web::V1::InvitationBuilder.new(@advisor, @params)
    @invitation = invitation_builder.build_invitation

    @errors_hash['invitation_errors'] = invitation_builder.errors unless @invitation.valid?
  end

  def build_client
    @client = Client.new(@client_params)
    @client.advisor_id = @advisor.id
    set_business

    @errors_hash['client_errors'] = @client.errors.full_messages unless @client.valid?
  end

  def check_and_save_invitation_and_client
    if @client && @invitation
      if @client.errors.blank? && @invitation.errors.blank?
        @client.save
        @invitation.client = @client
        @invitation.save
      end

    else
      @client.save if @client.errors.blank?
    end

    if @client.errors.blank?
      Permission.setup_system_documents_permissions_for_contact(@advisor, @client)
    end
  end

end
