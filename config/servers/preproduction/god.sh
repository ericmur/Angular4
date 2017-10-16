#!/bin/bash
#
# god       Startup script for God monitoring tool.
#
# chkconfig: - 85 15
# description: god monitors your system
#

CONF_DIR=/etc/god.conf
PID=/var/run/god.pid
LOG=/var/log/god.log
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RETVAL=0

case "$1" in
    start)
      god -P $PID -l $LOG --log-level warn
      god load $CONF_DIR
      RETVAL=$?
  ;;
    stop)
      kill `cat $PID`
      RETVAL=$?
  ;;
    restart)
      kill `cat $PID`
      god -P $PID -l $LOG --log-level warn
      god load $CONF_DIR
      RETVAL=$?
  ;;
    status)
      RETVAL=$?
  ;;
    *)
      echo "Usage: god {start|stop|restart|status}"
      exit 1
  ;;
esac

exit $RETVAL