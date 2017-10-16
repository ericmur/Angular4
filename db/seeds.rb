# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


ConsumerAccountType.load
Dimension.load
StandardBaseDocument.load

CloudService.find_or_create_by(name: CloudService::DROPBOX)
CloudService.find_or_create_by(name: CloudService::GOOGLE_DRIVE)
CloudService.find_or_create_by(name: CloudService::ONE_DRIVE)
CloudService.find_or_create_by(name: CloudService::EVERNOTE)
CloudService.find_or_create_by(name: CloudService::BOX)

StandardCategory.load
docyt_support_advisor = User.create!(:email => 'support@docyt.com', :password => 'test1234', :password_confirmation => 'test1234', :phone => '4159460430', :standard_category_id => StandardCategory::DOCYT_SUPPORT_ID, :first_name => 'Docyt', :last_name => 'Support', :app_type => User::WEB_APP)
docyt_support_advisor.confirm_phone
docyt_support_advisor.confirm_email

StandardGroup.load
FirstTimeStandardDocument.load
