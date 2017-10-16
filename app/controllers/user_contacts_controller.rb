class UserContactsController < ApplicationController
  def import
    @contact_list = current_user.iphone_contact_list
    if @contact_list.nil?
      @contact_list = current_user.build_iphone_contact_list 
      @contact_list.save!
    end

    params[:user_contacts].first.each do |k, user_contact|
      @contact_list.user_contacts.create(name: user_contact["name"], phones: user_contact["phones"], emails: user_contact["emails"])
    end if params[:user_contacts].present?

    current_offset = params[:current_offset].to_i 
    max_entries = params[:max_entries].to_i
    @contact_list.update_completion!(current_offset, UserContactList::CHUNK_SIZE, max_entries)

    respond_to do |format|
      format.json { 
        render json: { 
                contact_list_uploaded_offset: @contact_list.uploaded_offset, 
                contact_list_state: @contact_list.state 
              }, status: :ok 
      }
    end
  end
end