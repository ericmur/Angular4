class Api::Web::V1::BusinessBuilder
  def initialize(current_user, business_params, params)
    @current_user = current_user
    @business_params = business_params
    @business_partners_params = params[:business_partners]
    @update_standard_category = %w[1 true].include?(params[:business][:update_standard_category].to_s)
  end

  def create_business
    @business = Business.new(@business_params)
    ActiveRecord::Base.transaction(requires_new: true) do 
      begin
        @business.business_partners.build(user: @current_user)
        @business_partners_params.each do |partner_hash|
          @business.business_partners.build(user: User.find(partner_hash['user_id']))
        end if @business_partners_params.present?
        @business.save!
        if @update_standard_category
          update_user_standard_category!(@current_user, @business)
        end
        @business.generate_folder_settings!
        @business.generate_notifications_for_new_business!(@current_user)
        @business.migrate_partners_account_type_to_business!(@current_user)
        DocumentCacheService.update_cache([:folder_setting], @business.business_partners.pluck(:user_id))
      rescue => e
        @business.errors[:base] << e.message
        raise ActiveRecord::Rollback
      end
    end
    @business
  end

  private

  def update_user_standard_category!(user, business)
    user.standard_category = business.standard_category
    user.save!
  end
end