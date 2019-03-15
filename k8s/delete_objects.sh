#!/bin/bash
# DRYRUN=1 (only display what would be done)
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide object type as an argument, example: po, svc"
  exit 1
fi
if [ -z "$2" ]
then
  echo "$0: you need to provide object name prefix, example 'devstats-'"
  exit 1
fi
otype=$1
olen=${#2}
objs=`kubectl get $1`
pods=""
for obj in $objs
do
  base=${obj:0:$olen}
  if [ "$base" = "$2" ]
  then
    pods="$pods $obj"
  fi
done
if [ ! -z "$pods" ]
then
  if [ -z "$DRYRUN" ]
  then
    echo "Deleting $1: ${pods}"
    kubectl delete $1 ${pods}
  else
    echo "Would delete $1: ${pods}"
  fi
fi
