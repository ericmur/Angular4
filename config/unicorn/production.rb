working_directory "/home/deploy/docyt/current"
pid "/home/deploy/docyt/shared/tmp/pids/unicorn.pid"
stderr_path "/home/deploy/docyt/shared/log/unicorn.err"
stdout_path "/home/deploy/docyt/shared/log/unicorn.log"

listen "/home/deploy/docyt/shared/tmp/sockets/unicorn.sock"
worker_processes 2
timeout 30
preload_app true #Required to have unicorn preload app before forking worker processes to start newrelic agent

before_fork do |server, worker|
  # the following is highly recomended for Rails + "preload_app true"
  # as there's no need for the master process to hold a connection
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end

  # Before forking, kill the master process that belongs to the .oldbin PID.
  # This enables 0 downtime deploys.
  old_pid = "/home/deploy/docyt/shared/tmp/pids/unicorn.pid.oldbin"
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end

after_fork do |server, worker|
  # the following is *required* for Rails + "preload_app true",
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.establish_connection
    Rails.logger.info('Connected to ActiveRecord')
  end

  # if preload_app is true, then you may also want to check and
  # restart any other shared sockets/descriptors such as Memcached,
  # and Redis.  TokyoCabinet file handles are safe to reuse
  # between any number of forked children (assuming your kernel
  # correctly implements pread()/pwrite() system calls)
end