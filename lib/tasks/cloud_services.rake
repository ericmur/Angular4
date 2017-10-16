namespace :cloud_services do
  task :populate => :environment do |t, args|
    CloudService.create!(:name => CloudService::DROPBOX)
    CloudService.create!(:name => CloudService::GOOGLE_DRIVE)
  end
  
  task :scan_dropbox, [:user_id, :dropbox_uid, :auth_token, :folder_path] => :environment do |t, args|
    dropbox = CloudService.where(:name => 'Dropbox').first
    user = User.where(:id => args[:user_id]).first
    dropbox_authorization = dropbox.cloud_service_authorizations.where(:user_id => user.id, :uid => args[:dropbox_uid]).first
    if dropbox_authorization.nil?
      dropbox_authorization = dropbox.cloud_service_authorizations.build(:user_id => user.id, :uid => args[:dropbox_uid], :token => args[:auth_token])
    else
      dropbox_authorization.token = args[:auth_token]
    end
    dropbox_authorization.save!

    cloud_service_path = user.cloud_service_paths.where(:cloud_service_id => dropbox.id, :path => args[:folder_path]).first
    cloud_service_path.destroy if cloud_service_path
    cloud_service_path = user.cloud_service_paths.build(:cloud_service_id => dropbox.id, :path => args[:folder_path])
    cloud_service_path.save!
  end

  task :scan_drive, [:user_id, :drive_uid, :refresh_token, :folder_path] => :environment do |t, args|
    drive = CloudService.where(:name => CloudService::GOOGLE_DRIVE).first
    user = User.where(:id => args[:user_id]).first
    drive_authorization = drive.cloud_service_authorizations.where(:user_id => user.id, :uid => args[:drive_uid]).first
    if drive_authorization.nil?
      drive_authorization = drive.cloud_service_authorizations.build(:user_id => user.id, :uid => args[:drive_uid], :token => args[:refresh_token])
    else
      drive_authorization.token = args[:refresh_token]
    end
    drive_authorization.save!
    
    cloud_service_path = user.cloud_service_paths.where(:cloud_service_id => drive.id, :path => args[:folder_path]).first
    cloud_service_path.destroy if cloud_service_path
    cloud_service_path = user.cloud_service_paths.build(:cloud_service_id => drive.id, :path => args[:folder_path])
    cloud_service_path.save!
  end

  task :clear_suggestions, [:email] => :environment do |t, args|
    u = User.where(:email => args[:email]).first
    u.cloud_service_paths.each do |cpath|
      cpath.documents.where.not(:suggested_standard_document_id => nil).where(:standard_document_id => nil).each do |d|
        d.destroy
      end
    end
    u.cloud_service_paths.destroy_all
  end
end
