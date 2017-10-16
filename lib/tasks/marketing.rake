require 'csv'
#Get groups of users to send email campaign to. Prepare cohorts of users here.
namespace :marketing do
  task :daily_stats => :environment do |t, args|
    next unless Rails.env.production?
    today = Date.today
    users = User.where(created_at: (Time.now - 24.hours..Time.now))
    pages = Page.where(created_at: (Time.now - 24.hours..Time.now))
    documents = Document.where(created_at: (Time.now - 24.hours..Time.now))
    users_count = users.count
    pages_count = pages.count
    documents_count = documents.count

    attachment = {
        fallback: "Daily Marketing Statistics / #{today} - Users count: #{users_count} - Page count: #{pages_count}, Document count: #{documents_count}",
        text: "Daily Marketing Statistics / #{today}",
        color: "warning",
        author_name: "Docyt #{Rails.env}",
        title: "Marketing Statistics",
        fields: [
          {
            title: "New Users count",
            value: users_count,
            short: true
          },
          {
            title: "",
            value: "",
            short: true
          },
          {
            title: "New Pages count",
            value: pages_count,
            short: true
          },
          {
            title: "Documents count",
            value: documents_count,
            short: true
          }
        ]
      }

    notifier = Slack::Notifier.new SLACK_WEBHOOK_URL
    notifier.ping "Daily Marketing Statistics", attachments: [attachment], channel: "#marketing_stats", username: 'StatisticsBot'

    #Send users who uploaded documents today and the count
    top_users_hash = users.map { |u|
      { title: "Email: #{u.email}", value: "Documents: #{u.uploaded_documents.count}", short: false }
    }
    
    attachment = {
      fallback: "Daily Users / #{today} - Users count: #{users_count}",
      text: "Daily Users / #{today}",
      color: "warning",
      author_name: "Docyt #{Rails.env}",
      title: "Daily Users",
      fields: top_users_hash
    }

    notifier.ping "Daily Users", attachments: [attachment], channel: "#marketing_stats", username: 'StatisticsBot'
  end
  
  task :prepare_cohorts_email_csv, [:latest_app_version] => :environment do |t, args|
    latest_app_version = args[:latest_app_version]
    not_upgraded_users = User.where(["(mobile_app_version is null or mobile_app_version != ?) and email is not null", latest_app_version])
    zero_docs_users = User.where.not(:id => Document.where.not(:consumer_id => nil).uniq.pluck(:consumer_id)).where.not(:id => not_upgraded_users.pluck(:id)).where.not(:email => nil)
    everyone_else = User.where.not(:id => not_upgraded_users.pluck(:id)).where.not(:id => zero_docs_users.pluck(:id)).where.not(:email => nil)

    CSV.open("not_upgraded_users.csv", "wb") do |csv|
      csv << ["Email Address", "First Name", "Last Name"]
      not_upgraded_users.select(:email, :first_name, :last_name).each do |u|
        csv << [u.email, u.first_name, u.last_name]
      end
    end

    CSV.open("zero_docs_users.csv", "wb") do |csv|
      csv << ["Email Address", "First Name", "Last Name"]
      zero_docs_users.select(:email, :first_name, :last_name).each do |u|
        csv << [u.email, u.first_name, u.last_name]
      end
    end

    CSV.open("everyone_else.csv", "wb") do |csv|
      csv << ["Email Address", "First Name", "Last Name"]
      everyone_else.select(:email, :first_name, :last_name).each do |u|
        csv << [u.email, u.first_name, u.last_name]
      end
    end
  end

  desc "Get list of all users email and phone for master list in marketing csv"
  task :users_list => :environment do |t, args|
    CSV.open("users_master_list.csv", "wb") do |csv|
      csv << ["Email Address", "Phone"]
      not_upgraded_users.select(:email, :phone).each do |u|
        csv << [u.email, u.phone]
      end
    end
  end
end
