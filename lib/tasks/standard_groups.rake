namespace :standard_groups do
  task :load => :environment do
    StandardGroup.load
  end
end
