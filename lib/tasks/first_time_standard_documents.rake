namespace :first_time_standard_documents do
  task :load => :environment do
    FirstTimeStandardDocument.load
  end
end
