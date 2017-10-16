namespace :standard_categories do
  task :load => :environment do
    StandardCategory.load
  end

  task :create_custom, [:user_id, :name] => :environment do |t, args|
    StandardCategory.create!(:name => args[:name], :consumer_id => args[:user_id])
  end

  task :add_advisor, [:email, :password, :phone, :first_name, :last_name, :standard_category_name] => :environment do |t, args|
    standard_category = StandardCategory.where(:name => args[:standard_category_name]).first
    advisor = User.create!(:email => args[:email], :password => args[:password], :password_confirmation => args[:password], :phone => args[:phone], :standard_category_id => standard_category.id, :first_name => args[:first_name], :last_name => args[:last_name], :app_type => User::WEB_APP)
    advisor.confirm_phone
    advisor.confirm_email
  end

  task :add_clients_to_docyt_support => :environment do
    User.where("standard_category_id is null or standard_category_id != ?", StandardCategory::DOCYT_SUPPORT_ID).each do |consumer|
      consumer.connect_docyt_support_advisor
    end
  end

  task :add_client_to_advisor, [:user_id, :name, :advisor_id] => :environment do |t, args|
    consumer = User.where(:id => args[:user_id]).first
    advisor = User.where(:id => args[:advisor_id]).first
    raise "Advisor does not have name set" if advisor.name.blank?
    
    consumer.parse_fullname(args[:name])
    consumer.save!
    advisor.clients_as_advisor.create!(:consumer_id => consumer.id)
  end
end
