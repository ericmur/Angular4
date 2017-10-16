namespace :apns do
  desc "Create APNS App"
  task :create_app, [:name,:environment,:password,:path_to_cert] => :environment do |t, args|
    path_to_cert = args[:path_to_cert]
    path_to_cert = "#{args[:name]}.pem" unless path_to_cert.present?

    unless File.exists?(path_to_cert)
      raise "Unable to find cert file #{path_to_cert}"
    end

    app = Rpush::Apns::App.new
    app.name = args[:name]
    app.certificate = File.read(path_to_cert)
    app.environment = args[:environment]
    app.password = args[:password]
    app.connections = 1
    app.save!
  end

  desc "Push notification to device"
  task :push, [:device_token, :message] => :environment do |t, args|
    push_device = PushDevice.find_by_device_token(args[:device_token])
    if push_device
      push_device.push(args[:message])
    else
      puts "No Push Device found"
    end
  end

  desc "Push notification to user"
  task :push_user, [:consumer_email, :message] => :environment do |t, args|
    u = User.where(:email => args[:consumer_email]).first

    return unless installed_global_push_mobile_app?(u)

    u.push_devices.each do |push_device|
      if push_device
        push_device.push(args[:message])
      else
        puts "No Push Device found"
      end
    end
  end

  desc "Push notification to all users"
  task :push_all_users, [:message] => :environment do |t, args|
    User.all.each do |consumer|
      next unless installed_global_push_mobile_app?(consumer)
      consumer.push_devices.each do |push_device|
        if push_device
          push_device.push(args[:message])
        else
          puts "No Push Device found"
        end
      end
    end
  end

  desc "One time task - setup user_id in push_device"
  task :setup_user_id => :environment do |t, args|
    PushDevice.all.each do |pd|
      device = Device.where(:device_uuid => pd.device_uuid).first
      if device
        pd.user_id = device.user_id
        pd.save!
      end
    end
  end

  desc "Notify new mobile app version"
  task :notify_new_mobile_app_version, [:version, :message] => :environment do |t, args|
    version = args[:version]
    message = args[:message]

    raise "Require version number argument" if version.blank?
    message = "Docyt has great new features. Update now!" if message.blank?
    User.where(mobile_app_version: nil).union(User.where.not(mobile_app_version: version)).find_each do |consumer|

      notification = Notification.new
      notification.sender = nil
      notification.recipient = consumer
      notification.message = message
      notification.notification_type = Notification.notification_types[:new_mobile_app_update]
      if notification.save!
        notification.deliver([:push_notification])
      end

    end
  end

  def installed_global_push_mobile_app?(user)
    if user.mobile_app_version.blank?
      puts "User not installed mobile app or used old app version"
      return true
    end
    latest_version = "1.1.8"
    if Gem::Version.new(user.mobile_app_version) < Gem::Version.new(latest_version)
      puts "User installed mobile app < #{latest_version}"
      return false
    end
    return true
  end
end
