#!/bin/sh -e
# Copyright (C) nicholas a. evans <nick@ekenosen.net>
# See LICENSE.txt

### BEGIN INIT INFO
# Provides:          resque-web-<%= @app_name %>
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: resque-web init script for <%= @app_name %>
# Description:       resque-web manages the resque workers
### END INIT INFO

app_name="docyt-staging"
app_dir="/home/deploy/${app_name}/current"
pidfile="${app_dir}/tmp/pids/resque-web.pid"
run_as_user="deploy"
sleep_time_during_restart=5
stop_schedule="QUIT/30/INT/10/KILL/5"
bundler="/usr/local/bin/bundle"
environment="staging"
log_file="${app_dir}/log/resque-web.log"

. /etc/docyt/env.sh

export RAILS_ENV=${environment}

case "$1" in
  start)
    # I'm assuming that you are using bundler.  If you are using rip or
    # something else, you'll need to change this.  Remember to
    # keep the double-dash; e.g.: --startas CMD -- ARGS
    start-stop-daemon --start --pidfile ${pidfile} \
      --chuid ${run_as_user} --chdir ${app_dir} \
      --startas ${bundler} -- exec \
      resque-web -L --pid-file ${pidfile} -e ${environment} --log-file ${log_file} ${app_dir}/config/initializers/resque.rb
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