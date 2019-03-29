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
  echo "Usage $0 'command1,command2,..,commandN' max_seconds"
  exit 1
fi

commands=${1//,/ }
trials=0
maxTrials=$2

while true
do
  info=""
  running=0
  all=0
  for cmd in $commands
  do
    pid="/tmp/$cmd.pid"
    if [ -e $pid ]
    then
      if [ -z "$info" ]
      then
        info="${cmd} is running: ${pid} exists"
      else
        info="${info}, ${cmd} is running: ${pid} exists"
      fi
      running=$((running+1))
    fi
    all=$((all+1))
  done
  if [ "$running" -ge "1" ]
  then
    info="${info}, ${running}/${all} running"
    if [ "$trials" -eq "0" ]
    then
      echo "${info}, waiting"
    fi
    sleep 1
    trials=$((trials+1))
    if [ "$trials" -ge "$maxTrials" ]
    then
      echo "${info}, waited $maxTrials seconds, exiting"
      exit 1
    fi
  else
    break
  fi
done

s=0
for cmd in $commands
do
  s=$((s+1))
done

if [ "$trials" -gt "0" ]
then
  if [ "$s" -ge "2" ]
  then
    echo "$1 were running waited $trials seconds"
  else
    echo "$1 was running waited $trials seconds"
  fi
else
  if [ "$s" -ge "2" ]
  then
    echo "$1 were not running"
  else
    echo "$1 was not running"
  fi
fi
