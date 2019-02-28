#!/bin/bash
# DRYRUN=1 (only display what would be done)
if [ -z "${AWS_PROFILE}" ]
then
  echo "$0: you need to set AWS_PROFILE=... to run this script"
  exit 1
fi
cjobs=""
for job in `kubectl get cronjobs -l name=devstats -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'`
do
  base=${job:0:9}
  # echo "$base"
  if [ "$base" = "devstats-" ]
  then
    cjobs="${cjobs} ${job}"
  fi
done
if [ ! -z "$cjobs" ]
then
  if [ -z "$DRYRUN" ]
  then
    echo "Deleting cron jobs: ${cjobs}"
    kubectl delete pod ${cjobs}
  else
    echo "Would delete cronjobs: ${cjobs}"
  fi
fi
