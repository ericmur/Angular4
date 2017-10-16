#!/bin/sh -e
# Copyright (C) nicholas a. evans <nick@ekenosen.net>
# See LICENSE.txt

### BEGIN INIT INFO
# Provides:          resque-pool-<%= @app_name %>
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: resque-pool init script for <%= @app_name %>
# Description:       resque-pool manages the resque workers
### END INIT INFO

app_name="docyt"
app_dir="/home/deploy/${app_name}/current"
pidfile="${app_dir}/tmp/pids/resque-pool.pid"
run_as_user="deploy"
sleep_time_during_restart=5
stop_schedule="QUIT/30/INT/10/KILL/5"
bundler="/usr/local/bin/bundle"
environment="production"
stdout_log="${app_dir}/log/resque-pool.stdout.log"
stderr_log="${app_dir}/log/resque-pool.stderr.log"

. /etc/docyt/env.sh

case "$1" in
  start)
    # I'm assuming that you are using bundler.  If you are using rip or
    # something else, you'll need to change this.  Remember to
    # keep the double-dash; e.g.: --startas CMD -- ARGS
    start-stop-daemon --start --pidfile ${pidfile} \
      --chuid ${run_as_user} --chdir ${app_dir} \
      --startas ${bundler} -- exec \
      resque-pool -d -a ${app_name} -p ${pidfile} -E ${environment} -o ${stdout_log} -e ${stderr_log}
    ;;
  reload)
    start-stop-daemon --stop --pidfile ${pidfile} --signal HUP
    ;;
  graceful-stop)
    start-stop-daemon --stop --pidfile ${pidfile} --signal QUIT
    ;;
  quick-stop)
    start-stop-daemon --stop --pidfile ${pidfile} --signal INT
    ;;
  stop)
    start-stop-daemon --stop --pidfile ${pidfile} --retry=${stop_schedule}
    ;;
  restart)
    $0 stop
    sleep ${sleep_time_during_restart}
    $0 start
    ;;
  *)
    echo "Usage: $0 {start|stop|graceful-stop|quick-stop|restart|reload}"
    exit 1
    ;;
esac