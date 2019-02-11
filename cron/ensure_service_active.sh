#!/bin/bash
if [ -z "$1" ]
then
  echo "$0: required service name"
  exit 1
fi
function restart {
  echo "Stopping $1"
  /usr/sbin/service "$1" stop
  echo "Starting $1"
  /usr/sbin/service "$1" start
  echo "Restarted $1"
}
fn="/tmp/ensure_$1"
if [ -f "$fn" ]
then
  echo "Ensure process already running $fn file present"
  exit 2
fi
function finish {
  echo "Removing $fn"
  rm -f "$fn"
}
trap finish EXIT
> "$fn"
while true
do
  /usr/sbin/service "$1" status | grep 'Active: active' || restart "$1"
  sleep 30
done
