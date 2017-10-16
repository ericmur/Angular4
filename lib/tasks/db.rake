namespace :db do
  namespace :test do
    task :prepare => :environment do
      ActiveRecord::Base.establish_connection('test')
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      ActiveRecord::Base.establish_connection(ENV['RAILS_ENV'])
    end
  end
  
  desc "Dumps the database to db/docyt.dump"
  task :dump => :environment do
    cmd = []
    with_config do |app, host, db, user, password|
      cmd << "pg_dump"
      cmd << "--host #{host}" if host
      cmd << "--username #{user}" if user
      cmd << "--password #{password}" if password
      cmd << "--verbose --clean --no-owner --no-acl --format=c"
      cmd << "#{db} > #{Rails.root}/db/#{app}.dump"
    end
    cmd = cmd.join(' ')
    puts cmd
    exec cmd
  end

  desc "Restores the database dump at db/docyt.dump."
  task :restore => :environment do
    cmd = []
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    with_config do |app, host, db, user, password|
      cmd << "pg_restore"
      cmd << "--verbose"
      cmd << "--host #{host}" if host
      cmd << "--username #{user}" if user
      cmd << "--password #{password}" if user
      cmd << "--clean --no-owner --no-acl"
      cmd << "--dbname #{db} #{Rails.root}/db/#{app}.dump"
    end
    cmd = cmd.join(' ')
    puts cmd
    exec cmd
  end

  private

  def with_config
    yield Rails.application.class.parent_name.underscore,
      ActiveRecord::Base.connection_config[:host],
      ActiveRecord::Base.connection_config[:database],
      ActiveRecord::Base.connection_config[:username],
      ActiveRecord::Base.connection_config[:password]
  end
end
