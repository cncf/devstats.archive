#!/bin/bash
# NOLOCK=1 skip
if [ ! -z "$NOLOCK" ]
then
  exit 0
fi
if [ -z "$SKIPLOCK" ]
then
  if [ -f "/tmp/deploy.wip" ]
  then
    echo "another deploy process is running, exiting"
    exit 1
  fi
  wait_for_command.sh devstats 600 || exit 2
  cronctl.sh devstats off || exit 3
  cronctl.sh contrib.sh off || exit 4
  if [ -z "$FROM_WEBHOOK" ]
  then
    wait_for_command.sh webhook 600 || exit 5
    cronctl.sh webhook off || exit 6
    killall webhook
  fi
  echo 'All sync and deploy jobs stopped and disabled'
fi
