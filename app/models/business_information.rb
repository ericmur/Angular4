class BusinessInformation < ActiveRecord::Base
  belongs_to :standard_category
  has_one :user

  def migrate_to_business
    ActiveRecord::Base.transaction(requires_new: true) do
      begin
        business = Business.new
        business.name                 = self.name
        business.entity_type          = self.standard_category.name
        business.address_street       = self.address_street
        business.address_city         = self.address_city
        business.address_state        = self.address_state
        business.address_zip          = self.address_zip
        business.standard_category_id = self.standard_category_id
        business.business_partners.build(user: user)
        business.save!

        business.generate_folder_settings!
        business.generate_notifications_for_new_business!(user)
        business.migrate_partners_account_type_to_business!(user)
        DocumentCacheService.update_cache([:folder_setting], business.business_partners.pluck(:user_id))
      rescue => e
        puts e.message
        raise ActiveRecord::Rollback
      end
    end
  end
end
