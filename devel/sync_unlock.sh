#!/bin/bash
cronctl.sh devstats on || exit 1
if [ -z "$FROM_WEBHOOK" ]
then
  cronctl.sh webhook on || exit 2
fi
echo 'All sync and deploy jobs enabled'
