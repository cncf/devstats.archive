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
  wait_for_command.sh 'devstats,devstats_others,devstats_kubernetes,devstats_allprj' 900 || exit 2
  cronctl.sh devstats off || exit 3
  if [ -z "$FROM_WEBHOOK" ]
  then
    wait_for_command.sh webhook 900 || exit 4
    cronctl.sh webhook off || exit 5
    killall webhook
  fi
  echo 'All sync and deploy jobs stopped and disabled'
fi
