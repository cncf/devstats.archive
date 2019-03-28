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
  wait_for_command.sh devstats_others 600 || exit 3
  wait_for_command.sh devstats_kubernetes 600 || exit 4
  wait_for_command.sh devstats_allprj 600 || exit 5
  cronctl.sh devstats off || exit 6
  if [ -z "$FROM_WEBHOOK" ]
  then
    wait_for_command.sh webhook 600 || exit 7
    cronctl.sh webhook off || exit 8
    killall webhook
  fi
  echo 'All sync and deploy jobs stopped and disabled'
fi
