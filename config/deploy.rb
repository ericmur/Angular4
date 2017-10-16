# config valid only for current version of Capistrano
lock '3.4.0'

set :application, 'docyt'
set :repo_url, 'git@bitbucket.org:kmnss/docyt_server.git'
set :deploy_home, '/home/deploy'
#set :bundle_env_variables, { nokogiri_use_system_libraries: 1 }

set :assets_roles, [:web] #Needed so that assets:precompile is only done in web role server and not in app/resque servers. This will ensure the s3 assets' urls are the same via manifest.yml

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
#ask :branch, `git tag`.split("\n").last

# Default deploy_to directory is /var/www/my_app_name
# set :deploy_to, '/home/deploy/docyt'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push('config/database.yml') #Can include extra parameters for additional files

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system')

set :bundle_path, -> { release_path.join('vendor/bundle') }

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :assets_prefix, "#{fetch(:stage)}/assets"
namespace :resque_scheduler do
  task :stop do
    on roles(:resque) do
      execute :sudo, "god stop resque-scheduler"
    end
  end

  task :start do
    on roles(:resque) do
      execute :sudo, "god start resque-scheduler"
    end
  end
end

namespace :resque_pool do
  task :stop do
    on roles(:resque) do
      execute :sudo, "god stop resque-pool"
    end
  end

  task :start do
    on roles(:resque) do
      execute :sudo, "god start resque-pool"
    end
  end

  task :restart do
    on roles(:resque) do
      execute :sudo, "god restart resque-pool"
    end
  end
end

namespace :deploy do
  #Refer to https://github.com/capistrano/rails/issues/111 for this. It is needed for first time deployment error where .sprockets-manifest.json file is looked for
  task :fix_absent_manifest_bug
  on roles(:web) do
    within release_path do  execute :touch,
      release_path.join('public', fetch(:assets_prefix), '.sprockets-manifest.json')
    end
  end
  before :updated, 'deploy:fix_absent_manifest_bug'
  
  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  desc 'Restart'
  task :restart do
    on roles(:app), in: :sequence, wait: 1 do
      invoke "god:restart"
      invoke 'unicorn:legacy_restart'
    end

    on roles(:resque), in: :sequence, wait: 1 do
      if test("[ -f #{deploy_to}/current/tmp/pids/resque-scheduler.pid ]")
        invoke 'resque_scheduler:stop'
      end
      if test("[ -f #{deploy_to}/current/tmp/pids/resque-pool.pid ]")
        invoke 'resque_pool:stop'
      end
    end

    on roles(:resque), in: :sequence, wait: 1 do
      invoke 'resque_pool:start'
    end

    on roles(:resque), in: :sequence, wait: 1 do
      invoke 'resque_scheduler:start'
    end
  end
end

namespace :god do
  desc "Restart god"
  task :restart do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "service god restart"
    end
  end

  desc "Start god"
  task :start do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "service god start"
    end
  end

  desc "Stop god"
  task :stop do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "service god stop"
    end
  end
end

namespace :unicorn do
  desc "Restart unicorn"
  task :restart do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "god restart unicorn"
    end
  end
  desc "Start unicorn"
  task :start do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "god start unicorn"
    end
  end
  desc "Stop unicorn"
  task :stop do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "god stop unicorn"
    end
  end
end

namespace :nginx do
  desc "Restart nginx"
  task :restart do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "god restart nginx"
    end
  end
  desc "Start nginx"
  task :start do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "god start nginx"
    end
  end
  desc "Stop nginx"
  task :stop do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "god stop nginx"
    end
  end
end

namespace :deploy do
  task :setup do
    on roles(:all) do
      invoke 'setup:config'
    end
  end
end

namespace :setup do
  task :config do
    on roles(:all) do
      execute "mkdir -p #{deploy_to}/shared"
      execute "mkdir -p #{deploy_to}/shared/config"
      upload!("config/database.yml", "#{deploy_to}/shared/config/database.yml")
      upload!("config/servers/#{fetch(:stage)}/env.sh", "/tmp/env.sh")
      upload!("config/servers/#{fetch(:stage)}/ssl", fetch(:deploy_home), :recursive => true)
      execute :sudo, "mkdir -p /etc/docyt"
      execute :sudo, "mv /tmp/env.sh /etc/docyt/env.sh"
    end
  end
  
  task :init_scripts do
    on roles(:app) do
      invoke 'setup:god'
      invoke 'setup:nginx'
      invoke 'setup:unicorn'
    end

    on roles(:resque) do
      invoke 'setup:god'
      invoke 'setup:nginx_resque'
      invoke 'setup:resque_pool'
      invoke 'setup:resque_scheduler'
      invoke 'setup:resque_web'
    end
  end
  
  
  desc "Symlink nginx configuration"
  task :nginx do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "cp -f #{release_path}/config/servers/#{fetch(:stage)}/nginx.conf /etc/nginx/sites-enabled/#{fetch(:stage)}"
    end
  end

  desc "Symlink nginx configuration for resque-web"
  task :nginx_resque do
    on roles(:resque), in: :sequence, wait: 1 do
      upload!("config/servers/#{fetch(:stage)}/htpasswd", "/tmp/htpasswd")
      execute :sudo, "mv /tmp/htpasswd /etc/nginx/.htpasswd"
      execute :sudo, "cp -f #{release_path}/config/servers/#{fetch(:stage)}/resque-web-nginx.conf /etc/nginx/sites-enabled/resque-web-#{fetch(:stage)}"
    end
  end
  
  desc "Create init script for resque-pool and create log files if needed"
  task :resque_pool do
    on roles(:resque), in: :sequence, wait: 1 do
      execute :sudo, "cp -f #{release_path}/config/servers/#{fetch(:stage)}/resque-pool.sh /etc/init.d/resque-pool"
      execute :sudo, "chmod +x /etc/init.d/resque-pool"
      execute :touch, release_path.join('log/resque-pool.stdout.log')
      execute :touch, release_path.join('log/resque-pool.stderr.log')
    end
  end
  
  desc "Create init script for resque-scheduler and log file if needed"
  task :resque_scheduler do
    on roles(:resque), in: :sequence, wait: 1 do
      execute :sudo, "cp -f #{release_path}/config/servers/#{fetch(:stage)}/resque-scheduler.sh /etc/init.d/resque-scheduler"
      execute :sudo, "chmod +x /etc/init.d/resque-scheduler"
      execute :touch, release_path.join('log/resque-scheduler.log')
    end
  end
  
  desc "Create init script for resque-web and log file if needed"
  task :resque_web do
    on roles(:resque), in: :sequence, wait: 1 do
      execute :sudo, "cp -f #{release_path}/config/servers/#{fetch(:stage)}/resque-web.sh /etc/init.d/resque-web"
      execute :sudo, "chmod +x /etc/init.d/resque-web"
      execute :touch, release_path.join('log/resque-web.log')
    end
  end

  desc "Create init script for unicorn"
  task :unicorn do
      on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "cp -f #{release_path}/config/servers/#{fetch(:stage)}/unicorn.sh /etc/init.d/unicorn"
      execute :sudo, "chmod +x /etc/init.d/unicorn"
    end
  end
  
  desc "Create init script for god and symlink god configuration"
  task :god do
    on roles(:app), in: :sequence, wait: 1 do
      execute :sudo, "cp -f #{release_path}/config/servers/#{fetch(:stage)}/god.sh /etc/init.d/god"
      execute :sudo, "chmod +x /etc/init.d/god"
      execute :sudo, "ln -sf #{release_path}/config/monitoring/#{fetch(:stage)}/god.conf /etc/god.conf"
      #execute :sudo, "systemctl daemon-reload"
    end

    on roles(:resque), in: :sequence, wait: 1 do
      execute :sudo, "cp -f #{release_path}/config/servers/#{fetch(:stage)}/god.sh /etc/init.d/god"
      execute :sudo, "chmod +x /etc/init.d/god"
      execute :sudo, "ln -sf #{release_path}/config/monitoring/#{fetch(:stage)}/god.resque.conf /etc/god.conf"
      execute :sudo, "systemctl daemon-reload"
    end
  end
  
  
  desc "Check server uptime"
  task :uptime do
    on roles(:app), in: :parallel do |host|
      uptime = capture(:uptime)
      puts "#{host.hostname} reports: #{uptime}"
    end
  end
end

namespace :assets do
  desc "Copy manifest from web role to other roles"
  task :copy_manifest do
    manifest_contents, manifest_name = nil, nil
    assets_path = release_path.join('public', fetch(:assets_prefix))
    on roles(fetch(:assets_roles)), primary: true do
      manifest_name = capture(:ls, assets_path.join('.sprockets-manifest*.json')).strip
      manifest_contents = download! assets_path.join(manifest_name)
    end
    on roles(:resque, :app_secondary) do
      execute :rm, '-f', assets_path.join('.sprockets-manifest*.json')
      execute "mkdir -p #{assets_path}"
      upload! StringIO.new(manifest_contents), assets_path.join(manifest_name)
    end
  end
end

before :deploy, "deploy:setup"
after :deploy, "setup:init_scripts"
after "deploy:publishing", "assets:copy_manifest"
after "setup:init_scripts", "deploy:restart"

namespace :apns do
  task :create_app, :param do
    puts "Currently this features is not runs as expected. Execute rake apns:create_app directly in the server"
    #on roles(:app) do
    #  within "#{current_path}" do
    #    with rails_env: "#{fetch(:stage)}" do
    #      execute :rake, 'apns:create_app', args[:param]
    #    end
    #  end
    #end
  end
end
