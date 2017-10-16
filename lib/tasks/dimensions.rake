namespace :dimensions do
  task :load => :environment do
    Dimension.load
  end
end
