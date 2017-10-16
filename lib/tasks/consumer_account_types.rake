namespace :consumer_account_types do
  task :load => :environment do
    ConsumerAccountType.load
  end
end
