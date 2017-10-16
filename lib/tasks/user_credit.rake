namespace :user_credit do
  desc "Create User Credit"
  task create_user_credit: :environment do
    User.find_each do |user|
      if user.user_credit.blank?
        user_credit = user.build_user_credit
        user_credit.save!
      end
    end
  end

  desc "Generate Purchase Item"
  task generate_purchase_items: :environment do
    settings = Rails.application.config_for(:settings)
    bundle_identifier = settings['app_url_scheme'].gsub('://','')

    item_list = [
      ["$15.99 for 20 pages fax", "#{bundle_identifier}.Consumable.FaxPage20", "15.99", "20", 20],
      ["$8.99 for 10 pages fax", "#{bundle_identifier}.Consumable.FaxPage10", "8.99", "10", 10],
      ["$0.99 for 1 page fax", "#{bundle_identifier}.Consumable.FaxPage1", "0.99", "1", 0],
    ]
    item_list.each do |name, product_identifier, price, value, discount|
      PurchaseItem.create!(name: name, product_identifier: product_identifier, price: price, fax_credit_value: value, discount: discount)
    end
    Rake::Task['user_credit:print_purchase_items'].invoke
  end

  desc "Add Credit to User"
  task :purchase_item, [:user_id,:item_id] => :environment do |t, args|
    user = User.find(args[:user_id])
    user_credit = user.user_credit
    item = PurchaseItem.find(args[:item_id])
    transaction = user_credit.transactions.new(transactionable: item, fax_balance: item.fax_credit_value)
    transaction.save!
    transaction.complete!
  end

  desc "Print Purchase Items"
  task print_purchase_items: :environment do
    PurchaseItem.find_each do |purchase_item|
      puts "ID: [#{purchase_item.id}] Name: [#{purchase_item.name}] Price: [#{purchase_item.price}] Fax Cedit Value: [#{purchase_item.fax_credit_value}] ProductID: [#{purchase_item.product_identifier}]"
    end
  end

  desc "Print User Credit"
  task :print_user_credit, [:user_id] => :environment do |t, args|
    user = User.find(args[:user_id])
    user_credit = user.user_credit
    puts "Fax Credit: #{user_credit.fax_credit}"
    user_credit.transactions.each do |transaction|
      puts "Balance: #{transaction.fax_balance} Item: #{transaction.transactionable_type}:{#{transaction.transactionable_id}}"
    end
  end
end