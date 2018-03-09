#!/bin/bash
wait_for_command.sh devstats 3600 || exit 1
cronctl.sh devstats off || exit 2
wait_for_command.sh webhook 600 || exit 3
cronctl.sh webhook off || exit 4
killall webhook
echo 'All sync and deploy jobs stopped and disabled'
