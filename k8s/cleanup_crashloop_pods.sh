#!/bin/bash
# DRYRUN=1 (only display what would be done)
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
pods=""
for data in `awskubectl.sh get po | grep CrashLoopBackOff`
do
  pod=`echo "$data" | awk '{print $1}'`
  base=${pod:0:8}
  if [ "$base" = "devstats" ]
  then
    pods="${pods} ${pod}"
  fi
done
if [ ! -z "$pods" ]
then
  if [ -z "$DRYRUN" ]
  then
    echo "Deleting pods: ${pods}"
    kubectl delete pod ${pods}
  else
    echo "Would delete pods: ${pods}"
  fi
fi
