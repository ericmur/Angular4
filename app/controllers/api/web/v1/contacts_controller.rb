class Api::Web::V1::ContactsController < Api::Web::V1::ApiController
  before_action :get_contacts, only: :index
  before_action :get_contact,  only: :show

  def index
    render status: 200, json: @contacts, each_serializer: ::Api::Web::V1::ContactSerializer,
    meta: { pages_count: @contacts.total_pages }
  end

  def show
    render status: 200, json: @contact, serializer: ::Api::Web::V1::ContactSerializer
  end

  def create
    contact_builder = ::Api::Web::V1::ContactBuilder.new(current_advisor, contact_params)
    contact_builder.create_contact_and_invitation

    if contact_builder.errors.any?
      render status: 422, json: contact_builder.errors
    else
      render status: 201, json: contact_builder.contact, serializer: ::Api::Web::V1::ContactSerializer
    end
  end

  private

  def get_contacts
    @contacts = ::Api::Web::V1::ContactsQuery.new(current_advisor, params).get_contacts
  end

  def get_contact
    @contact = ::Api::Web::V1::ContactsQuery.new(current_advisor, params).get_contact
  end

  def contact_params
    params.require(:contact).permit(:email, :phone, :name, :standard_group_id,
      invitation: [:email, :phone, :email_invitation, :text_invitation])
  end

end
