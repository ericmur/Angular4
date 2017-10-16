#!/bin/sh -e

app_name="docyt-preproduction"
app_dir="/home/deploy/${app_name}/current"
pidfile="${app_dir}/tmp/pids/resque-scheduler.pid"
run_as_user="deploy"
sleep_time_during_restart=5
stop_schedule="QUIT/30/INT/10/KILL/5"
bundler="/usr/local/bin/bundle"
rails_environment="preproduction"
stdout_log="${app_dir}/log/resque-scheduler.log"

. /etc/docyt/env.sh

case "$1" in
  start)
    # I'm assuming that you are using bundler.  If you are using rip or
    # something else, you'll need to change this.  Remember to
    # keep the double-dash; e.g.: --startas CMD -- ARGS
    start-stop-daemon --start --pidfile ${pidfile} \
      --chuid ${run_as_user} --chdir ${app_dir} \
      --startas ${bundler} exec rake environment resque:scheduler -- \
      PIDFILE=${pidfile} BACKGROUND=yes DYNAMIC_SCHEDULE=yes APP_NAME=${app_name} RAILS_ENV=${rails_environment} LOGFILE=${stdout_log}
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
