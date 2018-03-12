#!/bin/bash
if [ -f "/tmp/deploy.wip" ]
then
  echo "another deploy process is running, exiting"
  exit 1
fi
wait_for_command.sh devstats 3600 || exit 2
cronctl.sh devstats off || exit 3
wait_for_command.sh webhook 600 || exit 4
cronctl.sh webhook off || exit 5
killall webhook
echo 'All sync and deploy jobs stopped and disabled'
