require 'slack-notifier'

namespace :statistics do
  desc "Daily Users/Pages Statistics"
  task daily: :environment do
    next unless Rails.env.production?
    today = Date.today
    users = User.where(created_at: (Time.now - 24.hours)..Time.now)
    pages = Page.where(created_at: (Time.now - 24.hours)..Time.now)
    documents = Document.where(created_at: (Time.now - 24.hours)..Time.now)
    users_count = users.count
    pages_count = pages.count
    total_pages_count = Page.count
    documents_count = documents.count
    total_documents_count = Document.count
    messages_count = Messagable::Message.where(created_at: (Time.now - 24.hours..Time.now)).count

    attachment = {
        fallback: "Daily Statistics / #{today} - Users count: #{users_count} - Page count: #{pages_count}",
        text: "Daily Statistics / #{today}",
        color: "warning",
        author_name: "Docyt #{Rails.env}",
        title: "Statistics",
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
            title: "Total Pages count",
            value: total_pages_count,
            short: true
          },
          {
            title: "Documents count",
            value: documents_count,
            short: true
          },
          {
            title: "Total Documents count",
            value: total_documents_count,
            short: true
          },
          {
            title: "Total Messages count",
            value: messages_count,
            short: true
          }

        ]
      }

    notifier = Slack::Notifier.new SLACK_WEBHOOK_URL
    %w[ @sid @sugam ].each do |channel|
      notifier.ping "Daily Statistics", attachments: [attachment], channel: channel, username: 'StatisticsBot'
    end

    AdminMailer.users_and_pages_statistics('daily', users_count, pages_count, total_pages_count, documents_count, total_documents_count, messages_count, today.strftime("%A - %B %d, %Y")).deliver_later

    #Send users who uploaded documents today and the count
    top_users_hash = documents.group(:consumer_id).order('count_id desc').count('id').map { |uid, count|
      c = User.find_by_id(uid)
      next if c.nil?
      { title: "Uploaded Documents count for: #{c.email ? c.email : c.phone}", value: count, short: false }
    }
    attachment = {
      fallback: "Daily Top Users / #{today} - Users count: #{users_count} - Page count: #{pages_count}",
      text: "Daily Top Users / #{today}",
      color: "warning",
      author_name: "Docyt #{Rails.env}",
      title: "Daily Top Users",
      fields: top_users_hash
    }

    %w[ @sid @sugam ].each do |channel|
      notifier.ping "Daily Top Users", attachments: [attachment], channel: channel, username: 'StatisticsBot'
    end
  end

  desc "Weekly Users/Pages Statistics"
  task weekly: :environment do
    next unless Rails.env.production?
    today = Date.today
    users_count = User.where(created_at: (today.beginning_of_week..today.end_of_week)).count
    pages_count = Page.where(created_at: (today.beginning_of_week..today.end_of_week)).count
    total_pages_count = Page.count
    documents = Document.where(created_at: (today.beginning_of_week..today.end_of_week))
    documents_count = documents.count
    total_documents_count = Document.count
    total_network_graph = UserContact.count
    messages_count = Messagable::Message.where(created_at: (today.beginning_of_week..today.end_of_week)).count

    attachment = {
        fallback: "Weekly Statistics / (#{today.beginning_of_week} - #{today.end_of_week}) - Users count: #{users_count} - Page count: #{pages_count}",
        text: "Weekly Statistics / (#{today.beginning_of_week} - #{today.end_of_week})",
        color: "warning",
        author_name: "Docyt #{Rails.env}",
        title: "Statistics",
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
            title: "Total Pages count",
            value: total_pages_count,
            short: true
          },
          {
            title: "Documents count",
            value: documents_count,
            short: true
          },
          {
            title: "Total Documents count",
            value: total_documents_count,
            short: true
          },
          {
            title: "Total Network Graph",
            value: total_network_graph,
            short: true
          },
          {
            title: "Total Messages count",
            value: messages_count,
            short: true
          }
        ]
      }

    notifier = Slack::Notifier.new SLACK_WEBHOOK_URL
    %w[ @sid @sugam ].each do |channel|
      notifier.ping "Weekly Statistics", attachments: [attachment], channel: channel, username: 'StatisticsBot'
    end

    AdminMailer.users_and_pages_statistics('weekly', users_count, pages_count, total_pages_count, documents_count, total_documents_count, messages_count, today.beginning_of_week.strftime("%A - %B %d, %Y"), today.end_of_week.strftime("%A - %B %d, %Y")).deliver_later

    #Send users who uploaded documents today and the count
    top_users_hash = documents.group(:consumer_id).order('count_id desc').count('id').map { |uid, count|
      c = User.find_by_id(uid)
      next if c.nil?
      { title: "Uploaded Documents count for: #{c.email ? c.email : c.phone}", value: count, short: false }
    }
    attachment = {
      fallback: "Weekly Top Users / (#{today.beginning_of_week} - #{today.end_of_week}) - Users count: #{users_count} - Page count: #{pages_count}",
      text: "Weekly Top Users / (#{today.beginning_of_week} - #{today.end_of_week})",
      color: "warning",
      author_name: "Docyt #{Rails.env}",
      title: "Weekly Top Users",
      fields: top_users_hash
    }

    %w[ @sid @sugam ].each do |channel|
      notifier.ping "Weekly Top Users", attachments: [attachment], channel: channel, username: 'StatisticsBot'
    end
  end
end
