#!/bin/bash
# NOLOCK=1 skip
if [ ! -z "$NOLOCK" ]
then
  exit 0
fi
set -o pipefail
if ([ -z "$1" ] || [ -z "$2" ])
then
  echo "Usage $0 command max_seconds"
  exit 1
fi
command=$1
pid="/tmp/$command.pid"
trials=0
maxTrials=$2
while true
do
  if [ -e $pid ]
  then
    if [ "$trials" -eq "0" ]
    then
      echo "$command is running: $pid exists, waiting"
    fi
    sleep 1
    trials=$((trials+1))
    if [ "$trials" -ge "$maxTrials" ]
    then
      echo "$command is still running: $pid exists, waited $maxTrials seconds, exiting"
      exit 1
    fi
  else
    break
  fi
done
if [ "$trials" -gt "0" ]
then
  echo "$command was running waited $trials seconds"
else
  echo "$command was not running"
fi
