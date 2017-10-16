rails_env   = ENV['RAILS_ENV']  || "staging"
rails_root  = ENV['RAILS_ROOT'] || "/home/deploy/docyt-staging/current"

God.watch do |w|
  w.dir      = "#{rails_root}"
  w.name     = "resque-scheduler"
  w.group    = 'resque'
  w.interval = 30.seconds
  w.env      = { "RAILS_ENV" => rails_env }
  w.start = "sudo /etc/init.d/resque-scheduler start"
  w.stop = "sudo /etc/init.d/resque-pool graceful-stop"
  w.restart = "sudo /etc/init.d/resque-scheduler restart"

  w.pid_file = "#{rails_root}/tmp/pids/resque-scheduler.pid"
  w.behavior(:clean_pid_file)

  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 5.seconds
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end
end