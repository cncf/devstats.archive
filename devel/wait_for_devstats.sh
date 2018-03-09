#!/bin/bash
set -o pipefail
pid=/tmp/devstats.pid
trials=0
maxTrials=3600
while true
do
  if [ -e $pid ]
  then
    if [ "$trials" -eq "0" ]
    then
      echo "DevStats is running: $pid exists, waiting"
    fi
    sleep 1
    trials=$((trials+1))
    if [ "$trials" -ge "$maxTrials" ]
    then
      echo "DevStats is still running: $pid exists, waited $maxTrials seconds, exiting"
      exit 1
    fi
  else
    break
  fi
done
if [ "$trials" -gt "0" ]
then
  echo "DevStats was running waited $trials seconds"
else
  echo "DevStats was not running"
fi
