#!/bin/bash
# NOLOCK=1 skip
if [ ! -z "$NOLOCK" ]
then
  exit 0
fi
if [ -z "$SKIPLOCK" ]
then
  cronctl.sh devstats on || exit 1
  cronctl.sh contrib.sh on || exit 2
  if [ -z "$FROM_WEBHOOK" ]
  then
    cronctl.sh webhook on || exit 3
  fi
  echo 'All sync and deploy jobs enabled'
fi
